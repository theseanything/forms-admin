# frozen_string_literal: true

class WelshChangeDetectionService
  IGNORED_FORM_FIELDS = %w[name privacy_policy_url].freeze
  IGNORED_STEP_FIELDS = %w[answer_settings].freeze

  TRANSLATABLE_FORM_FIELDS = %w[
    declaration_markdown what_happens_next_markdown support_email support_phone
    support_url support_url_text payment_url
  ].freeze

  TRANSLATABLE_STEP_FIELDS = %w[question_text hint_text page_heading guidance_markdown].freeze

  def initialize(form)
    @form = form
  end

  def update_welsh?
    return false unless @form.available_languages.include?("cy")

    changes.any?
  end

  def changes
    return [] unless @form.available_languages.include?("cy")

    live_content = @form.live_form_document&.content
    draft_content = @form.draft_form_document&.content || @form.draft_content_service.content_hash

    return [{ type: :no_welsh_document }] if live_content.blank? && !draft_content.dig("available_languages")&.include?("cy")

    detected = []
    detected.concat(detect_form_field_changes(live_content, draft_content))
    detected.concat(detect_step_changes(live_content, draft_content))
    detected
  end

private

  def detect_form_field_changes(live_content, draft_content)
    return [] if live_content.blank?

    TRANSLATABLE_FORM_FIELDS.filter_map do |field|
      en_val = draft_content.dig(field, "en") || draft_content[field]
      cy_val = draft_content.dig(field, "cy")
      if en_val.present? && cy_val.blank?
        { type: :new_field, field: field.to_sym, scope: :form }
      end
    end
  end

  def detect_step_changes(live_content, draft_content)
    live_steps = live_content&.fetch("steps", []) || []
    draft_steps = draft_content.fetch("steps", []) || []

    changes = []
    live_ids = live_steps.map { |s| s["id"] }
    draft_ids = draft_steps.map { |s| s["id"] }

    (draft_ids - live_ids).each do |new_id|
      step = draft_steps.find { |s| s["id"] == new_id }
      changes << { type: :new_page, page_id: new_id, position: step["position"] }
    end

    (live_ids - draft_ids).each do |deleted_id|
      changes << { type: :deleted_page, external_id: deleted_id }
    end

    draft_steps.each do |draft_step|
      live_step = live_steps.find { |s| s["id"] == draft_step["id"] }
      next unless live_step

      TRANSLATABLE_STEP_FIELDS.each do |field|
        en_changed = draft_step.dig(field, "en") != live_step.dig(field, "en")
        cy_blank = draft_step.dig(field, "cy").blank?
        changes << { type: :new_field, field: field.to_sym, page_id: draft_step["id"], scope: :page } if en_changed && cy_blank
      end
    end

    changes
  end
end
