# frozen_string_literal: true

class RevertDraftFormService
  attr_reader :form

  def initialize(form)
    @form = form
  end

  def revert_draft_from_form_document(_tag = :live)
    return false if form.draft_form_document_id.blank?

    FormDocumentOperationsService.new(form).discard_draft!
    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to discard draft for form #{form.id}: #{e.message}")
    false
  end
end
