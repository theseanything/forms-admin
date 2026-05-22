# frozen_string_literal: true

module SeedFormsHelper
  module_function

  def create_live_form!(user:, name:, steps:, conditions: [], **attrs)
    form = Form.create!(
      creator_id: user.id,
      question_section_completed: attrs.fetch(:question_section_completed, true),
      declaration_section_completed: attrs.fetch(:declaration_section_completed, true),
      share_preview_completed: attrs.fetch(:share_preview_completed, true),
      welsh_completed: attrs.fetch(:welsh_completed, false),
    )

    FormDocumentFactoryHelpers.apply_form_content!(
      form,
      name:,
      submission_email: attrs[:submission_email],
      submission_type: attrs[:submission_type] || "email",
      submission_format: attrs[:submission_format] || [],
      privacy_policy_url: attrs[:privacy_policy_url] || "https://www.gov.uk/help/privacy-notice",
      support_email: attrs[:support_email],
      support_phone: attrs[:support_phone],
      what_happens_next_markdown: attrs[:what_happens_next_markdown] || "Test",
      declaration_markdown: attrs[:declaration_markdown] || "",
      available_languages: attrs[:available_languages] || %w[en],
      send_daily_submission_batch: attrs[:send_daily_submission_batch],
      send_weekly_submission_batch: attrs[:send_weekly_submission_batch],
    )

    if attrs[:name_cy]
      form.name_cy = attrs[:name_cy]
    end

    hash = form.draft_content_service.content_hash
    built_steps = steps.each_with_index.map do |step_attrs, index|
      FormDocumentFactoryHelpers.build_step_attrs(
        position: index + 1,
        question_text: step_attrs[:question_text],
        answer_type: step_attrs[:answer_type],
        is_optional: step_attrs.fetch(:is_optional, false),
        is_repeatable: step_attrs.fetch(:is_repeatable, false),
        answer_settings: step_attrs[:answer_settings],
        hint_text: step_attrs[:hint_text],
      ).tap do |step|
        if step_attrs[:question_text_cy]
          step["question_text"]["cy"] = step_attrs[:question_text_cy]
        end
        if step_attrs[:hint_text_cy]
          step["hint_text"] = { "en" => step_attrs[:hint_text] || "", "cy" => step_attrs[:hint_text_cy] }
        end
      end
    end
    built_steps.each_with_index { |step, i| step["next_step_id"] = built_steps[i + 1]&.dig("id") }
    hash["steps"] = built_steps
    hash["start_page"] = built_steps.first&.dig("id")
    hash["s3_bucket_region"] = attrs[:s3_bucket_region] if attrs[:s3_bucket_region]
    FormDocumentOperationsService.new(form).save_draft_content!(hash)

    pages = form.draft_content_service.steps_for_list
    conditions.each do |condition_attrs|
      routing_page = pages[condition_attrs.fetch(:routing_index)]
      check_page = condition_attrs.key?(:check_index) ? pages[condition_attrs[:check_index]] : routing_page
      goto_page = condition_attrs[:goto_index] ? pages[condition_attrs[:goto_index]] : nil
      FormCondition.create_and_update_form!(
        form_id: form.id,
        routing_page_id: routing_page.id,
        check_page_id: check_page.id,
        goto_page_id: goto_page&.id,
        answer_value: condition_attrs[:answer_value],
        skip_to_end: condition_attrs[:skip_to_end] || false,
        exit_page_heading: condition_attrs[:exit_page_heading],
        exit_page_markdown: condition_attrs[:exit_page_markdown],
      )
    end

    form.set_task_status_service(TaskStatusService.new(form:, current_user: user))
    FormDocumentFactoryHelpers.publish_form!(form)
    form.reload
  end
end
