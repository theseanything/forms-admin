# frozen_string_literal: true

class ArchiveFormService
  attr_reader :form, :current_user

  def initialize(form:, current_user:)
    @form = form
    @current_user = current_user
  end

  def archive
    FormDocumentOperationsService.new(form).archive!
    SubmissionEmailMailer.alert_processor_form_archive(
      processor_email: form.submission_email,
      form_name: form.name,
      archived_by_name: current_user.name,
      archived_by_email: current_user.email,
    ).deliver_now
  end

  def archive_welsh_only
    return unless form.live_form_document&.content&.dig("available_languages")&.include?("cy")

    operations = FormDocumentOperationsService.new(form)
    was_ready = form.all_ready_for_live?(ignore_missing_welsh: true)
    operations.remove_welsh!
    return unless form.is_live? && form.draft_form_document.present?

    if was_ready
      form.update!(
        share_preview_completed: true,
        question_section_completed: true,
        declaration_section_completed: true,
      )
    end
    operations.publish!
  end
end
