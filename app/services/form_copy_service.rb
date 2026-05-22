# frozen_string_literal: true

class FormCopyService
  include LoggingHelper

  def initialize(form, logged_in_user)
    @form = form
    @logged_in_user = logged_in_user
  end

  def copy(tag: "draft")
    source_document = resolve_source_document(tag)
    return false if source_document.blank?

    content = JSON.parse(JSON.generate(source_document.content))
    content["name"] = TranslatableString.normalize(content["name"])
    content["name"]["en"] = "Copy of #{content['name']['en']}"
    if content["name"]["cy"].present?
      content["name"]["cy"] = "Copy of #{content['name']['cy']}"
    end
    content.delete("live_at")
    content["form_id"] = nil

    ActiveRecord::Base.transaction do
      @copied_form = Form.create!(
        creator_id: @logged_in_user.id,
        copied_from_id: @form.id,
      )
      FormDocumentOperationsService.new(@copied_form).save_draft_content!(content)
      GroupForm.create!(group_id: @form.group.id, form_id: @copied_form.id)
    end

    log_form_copied(original_form_id: @form.id, copied_form_id: @copied_form.id, creator_id: @logged_in_user.id)
    @copied_form.reload
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to copy form #{@form.id}: #{e.message}")
    false
  end

private

  def resolve_source_document(tag)
    case tag.to_s
    when "draft"
      @form.draft_form_document
    when "live"
      @form.live_form_document
    when "archived"
      @form.archived? ? @form.live_form_document : nil
    end
  end
end
