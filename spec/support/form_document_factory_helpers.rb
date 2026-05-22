# frozen_string_literal: true

module FormDocumentFactoryHelpers
  module_function

  def build_step_attrs(overrides = {})
    id = ExternalIdProvider.generate_unique_id_for(FormStepId)
    {
      "id" => id,
      "type" => "question",
      "position" => overrides[:position] || 1,
      "question_text" => { "en" => overrides[:question_text] || Faker::Lorem.question.truncate(250) },
      "hint_text" => { "en" => overrides[:hint_text] || "" },
      "page_heading" => { "en" => overrides[:page_heading] || "" },
      "guidance_markdown" => { "en" => overrides[:guidance_markdown] || "" },
      "answer_type" => overrides[:answer_type] || FormStep::ANSWER_TYPES_WITHOUT_SETTINGS.sample,
      "data" => {
        "is_optional" => overrides.fetch(:is_optional, false),
        "is_repeatable" => overrides.fetch(:is_repeatable, false),
        "answer_settings" => overrides[:answer_settings],
      }.compact,
      "routing_conditions" => overrides[:routing_conditions] || [],
    }
  end

  def apply_form_content!(form, attrs = {})
    hash = form.draft_content_service.content_hash
    hash["name"] = { "en" => attrs[:name] } if attrs[:name]
    hash["submission_email"] = attrs[:submission_email] if attrs.key?(:submission_email)
    hash["submission_type"] = attrs[:submission_type] if attrs[:submission_type]
    hash["submission_format"] = attrs[:submission_format] if attrs[:submission_format]
    hash["privacy_policy_url"] = { "en" => attrs[:privacy_policy_url] } if attrs[:privacy_policy_url]
    hash["support_email"] = { "en" => attrs[:support_email] } if attrs[:support_email]
    hash["what_happens_next_markdown"] = { "en" => attrs[:what_happens_next_markdown] } if attrs[:what_happens_next_markdown]
    hash["declaration_markdown"] = { "en" => attrs[:declaration_markdown] } if attrs[:declaration_markdown]
    hash["payment_url"] = { "en" => attrs[:payment_url] } if attrs[:payment_url]
    hash["available_languages"] = attrs[:available_languages] if attrs[:available_languages]
    hash["send_copy_of_answers"] = attrs[:send_copy_of_answers] if attrs[:send_copy_of_answers]
    hash["send_daily_submission_batch"] = attrs[:send_daily_submission_batch] if attrs.key?(:send_daily_submission_batch)
    hash["send_weekly_submission_batch"] = attrs[:send_weekly_submission_batch] if attrs.key?(:send_weekly_submission_batch)
    FormDocumentOperationsService.new(form).save_draft_content!(hash)
  end

  def add_steps_to_form!(form, count: 5, **step_overrides)
    steps = (1..count).map do |i|
      build_step_attrs(position: i, **step_overrides)
    end
    steps.each_with_index do |step, i|
      step["next_step_id"] = steps[i + 1]&.dig("id")
    end
    hash = form.draft_content_service.content_hash
    hash["steps"] = steps
    hash["start_page"] = steps.first["id"]
    FormDocumentOperationsService.new(form).save_draft_content!(hash)
  end

  def publish_form!(form)
    form.set_task_status_service(
      TaskStatusService.new(form:, current_user: OpenStruct.new(name: "Test", email: "test@example.gov.uk")),
    )
    FormDocumentOperationsService.new(form).publish!
  end

  def create_live_form!(form)
    publish_form!(form)
    form.reload
  end

  def create_live_with_draft!(form)
    create_live_form!(form) unless form.live_form_document_id.present?
    FormDocumentOperationsService.new(form).ensure_draft!
    form.reload
  end

  def archive_form!(form)
    FormDocumentOperationsService.new(form).archive!
    form.reload
  end

  def apply_lifecycle_state!(form, state)
    case state.to_s.to_sym
    when :live
      create_live_form!(form) unless form.live_form_document_id.present?
    when :live_with_draft
      create_live_with_draft!(form)
    when :archived
      create_live_form!(form) unless form.live_form_document_id.present?
      archive_form!(form) unless form.archived?
    when :archived_with_draft
      create_live_form!(form) unless form.live_form_document_id.present?
      archive_form!(form) unless form.archived?
      FormDocumentOperationsService.new(form).ensure_draft!
    end
    form.reload
  end
end
