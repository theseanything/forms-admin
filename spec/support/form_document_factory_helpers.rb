# frozen_string_literal: true

module FormDocumentFactoryHelpers
  module_function

  def build_step_attrs(overrides = {})
    id = ExternalIdProvider.generate_unique_id_for(FormStepId)
    {
      "id" => id,
      "type" => "question",
      "position" => overrides[:position] || 1,
      "question_text" => translatable_field(overrides[:question_text], overrides[:question_text_cy]),
      "hint_text" => translatable_field(overrides[:hint_text], overrides[:hint_text_cy]),
      "page_heading" => translatable_field(overrides[:page_heading], overrides[:page_heading_cy]),
      "guidance_markdown" => translatable_field(overrides[:guidance_markdown], overrides[:guidance_markdown_cy]),
      "answer_type" => overrides[:answer_type] || FormStep::ANSWER_TYPES_WITHOUT_SETTINGS.sample,
      "data" => {
        "is_optional" => overrides.fetch(:is_optional, false),
        "is_repeatable" => overrides.fetch(:is_repeatable, false),
        "answer_settings" => overrides[:answer_settings],
        "answer_settings_cy" => normalize_answer_settings_cy(overrides[:answer_settings_cy]),
      }.compact,
      "routing_conditions" => overrides[:routing_conditions] || [],
    }
  end

  def translatable_field(en_value, cy_value = nil)
    result = {}
    if en_value.present?
      result["en"] = en_value
    elsif cy_value.present?
      result["en"] = "English"
    else
      result["en"] = ""
    end
    result["cy"] = cy_value if cy_value.present?
    result
  end

  def normalize_answer_settings_cy(settings)
    return settings if settings.nil? || settings.is_a?(Hash)

    settings.respond_to?(:to_h) ? settings.to_h.stringify_keys : settings
  end

  def apply_form_content!(form, attrs = {})
    hash = form.draft_content_service.content_hash
    hash["name"] = translatable_field(attrs[:name], attrs[:name_cy]) if attrs[:name] || attrs[:name_cy]
    hash["submission_email"] = attrs[:submission_email] if attrs.key?(:submission_email)
    hash["submission_type"] = attrs[:submission_type] if attrs[:submission_type]
    hash["submission_format"] = attrs[:submission_format] if attrs[:submission_format]
    hash["privacy_policy_url"] = translatable_field(attrs[:privacy_policy_url], attrs[:privacy_policy_url_cy]) if attrs[:privacy_policy_url] || attrs[:privacy_policy_url_cy]
    hash["support_email"] = translatable_field(attrs[:support_email], attrs[:support_email_cy]) if attrs[:support_email] || attrs[:support_email_cy]
    hash["support_phone"] = translatable_field(attrs[:support_phone], attrs[:support_phone_cy]) if attrs[:support_phone] || attrs[:support_phone_cy]
    hash["support_url"] = translatable_field(attrs[:support_url], attrs[:support_url_cy]) if attrs[:support_url] || attrs[:support_url_cy]
    hash["support_url_text"] = translatable_field(attrs[:support_url_text], attrs[:support_url_text_cy]) if attrs[:support_url_text] || attrs[:support_url_text_cy]
    hash["what_happens_next_markdown"] = translatable_field(attrs[:what_happens_next_markdown], attrs[:what_happens_next_markdown_cy]) if attrs[:what_happens_next_markdown] || attrs[:what_happens_next_markdown_cy]
    hash["declaration_markdown"] = translatable_field(attrs[:declaration_markdown], attrs[:declaration_markdown_cy]) if attrs[:declaration_markdown] || attrs[:declaration_markdown_cy]
    hash["payment_url"] = translatable_field(attrs[:payment_url], attrs[:payment_url_cy]) if attrs[:payment_url] || attrs[:payment_url_cy]
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

  def report_form_document_json(form, tag: "live", **extra)
    doc = form.live_form_document
    json = doc.as_json
    json["tag"] = tag
    json["content"] = FormDocument::LocaleProjection.project(doc.content, language: "en")
    json.merge(extra.stringify_keys)
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
