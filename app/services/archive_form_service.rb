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

    FormDocumentOperationsService.new(form).remove_welsh!
  end
end
