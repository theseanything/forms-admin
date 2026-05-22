# frozen_string_literal: true

class FormDocumentOperationsService
  attr_reader :form

  def initialize(form)
    @form = form
  end

  def ensure_draft!
    return form.draft_form_document if form.draft_form_document_id.present?

    raise ActiveRecord::RecordNotFound, "Cannot create draft without a live version" if form.live_form_document.blank?

    ActiveRecord::Base.transaction do
      draft = FormDocument.create!(
        form:,
        content: deep_dup_content(form.live_form_document.content),
        supersedes_id: form.live_form_document_id,
      )
      form.update!(draft_form_document_id: draft.id, share_preview_completed: false)
      draft
    end
  end

  def save_draft_content!(content_hash)
    draft = form.draft_form_document || create_initial_draft!(content_hash)
    raise ActiveRecord::ReadOnlyRecord, "Cannot update live form document" if draft.readonly?

    content = content_hash.deep_stringify_keys
    content["form_id"] = form.id.to_s
    content["form_slug"] = derive_form_slug(content)

    draft.update!(content:)
    form.touch
    draft
  end

  def publish!
    if form.draft_form_document.blank?
      form.errors.add(:base, "No draft to publish")
      raise ActiveRecord::RecordInvalid, form
    end
    unless form.all_ready_for_live?(ignore_missing_welsh: true)
      form.errors.add(:base, "Form is not ready to go live")
      raise ActiveRecord::RecordInvalid, form
    end

    ActiveRecord::Base.transaction do
      previous_live_id = form.live_form_document_id
      live_content = deep_dup_content(form.draft_form_document.content)
      published_at = Time.current
      live_content["live_at"] = published_at.iso8601
      live_content["first_made_live_at"] ||= form.first_made_live_at&.iso8601 || published_at.iso8601
      live_content["created_at"] ||= form.created_at&.iso8601 || published_at.iso8601
      form.first_made_live_at ||= published_at

      live_doc = FormDocument.create!(
        form:,
        content: live_content,
        published_at: Time.current,
        supersedes_id: previous_live_id,
      )

      updates = {
        live_form_document_id: live_doc.id,
        draft_form_document_id: nil,
        archived: false,
        first_made_live_at: form.first_made_live_at,
      }
      form.update!(updates)
      live_doc
    end
  end

  def discard_draft!
    return false if form.draft_form_document_id.blank?

    ActiveRecord::Base.transaction do
      draft = form.draft_form_document
      form.update!(draft_form_document_id: nil)
      draft.destroy!
    end
    true
  end

  def revert_draft_to_live!
    return false if form.live_form_document.blank?

    ActiveRecord::Base.transaction do
      if form.draft_form_document.present?
        form.draft_form_document.update!(content: deep_dup_content(form.live_form_document.content))
      else
        ensure_draft!
        form.draft_form_document.update!(content: deep_dup_content(form.live_form_document.content))
      end
    end
    true
  end

  def archive!
    if form.live_form_document_id.blank?
      form.errors.add(:base, "Cannot archive form without live version")
      raise ActiveRecord::RecordInvalid, form
    end

    form.update!(archived: true, draft_form_document_id: nil)
    form.draft_form_document&.destroy!
    form
  end

  def unarchive_and_publish!
    form.update!(archived: false)
    publish!
  end

  def save_draft!
    if form.live_form_document_id.present? && form.draft_form_document_id.blank?
      ensure_draft!
    else
      form.save!
    end
  end

  def remove_welsh!
    ensure_draft! if form.draft_form_document.blank? && form.live_form_document.present?
    draft = form.draft_form_document
    return unless draft

    content = draft.content.deep_dup
    content["available_languages"] = %w[en]
    strip_cy_from_content!(content)
    save_draft_content!(content)
    form.update!(welsh_completed: false)
    form.reload
  end

private

  def create_initial_draft!(content_hash)
    draft = FormDocument.create!(form:, content: content_hash)
    form.update!(draft_form_document_id: draft.id)
    draft
  end

  def deep_dup_content(content)
    JSON.parse(JSON.generate(content))
  end

  def derive_form_slug(content)
    name = TranslatableString.for_locale(content["name"], locale: :en)
    name.present? ? name.parameterize : ""
  end

  def strip_cy_from_content!(content)
    content.each_value do |v|
      v.delete("cy") if v.is_a?(Hash) && v.key?("cy")
    end
    Array(content["steps"]).each do |step|
      %w[question_text hint_text page_heading guidance_markdown exit_page_heading exit_page_markdown].each do |key|
        step[key]&.delete("cy") if step[key].is_a?(Hash)
      end
      step.dig("data")&.delete("answer_settings_cy")
      Array(step["routing_conditions"]).each do |c|
        %w[exit_page_heading exit_page_markdown].each do |key|
          c[key]&.delete("cy") if c[key].is_a?(Hash)
        end
      end
    end
  end
end
