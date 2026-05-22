require "rails_helper"

describe ArchiveFormService do
  subject(:archive_form_service) do
    described_class.new(form:, current_user:)
  end

  let(:submission_email) { "submission@example.gov.uk" }
  let(:form) { create(:form, :live, submission_email:) }
  let(:current_user) { build(:user) }
  let(:delivery) { double }

  describe "#archive" do
    before do
      allow(SubmissionEmailMailer).to receive(:alert_processor_form_archive)
                                        .with(anything)
                                        .and_return(delivery)
      allow(delivery).to receive(:deliver_now).with(no_args)
    end

    it "archives the form" do
      expect {
        archive_form_service.archive
      }.to change { form.reload.archived }.from(false).to(true)
    end

    it "sends an email to the submission email address" do
      expect(SubmissionEmailMailer).to receive(:alert_processor_form_archive)
                                         .with(processor_email: submission_email,
                                               form_name: form.name,
                                               archived_by_name: current_user.name,
                                               archived_by_email: current_user.email)
      expect(delivery).to receive(:deliver_now).with(no_args)
      archive_form_service.archive
    end
  end

  describe "#archive_welsh_only" do
    let!(:form) do
      f = create(:form, :ready_for_live, available_languages: %w[en cy], welsh_completed: true)
      hash = f.draft_content_service.content_hash
      hash["available_languages"] = %w[en cy]
      hash["name"] = { "en" => f.name, "cy" => "Welsh #{f.name}" }
      FormDocumentOperationsService.new(f).save_draft_content!(hash)
      FormDocumentFactoryHelpers.create_live_form!(f)
      f.reload
    end

    it "removes welsh from available languages" do
      archive_form_service.archive_welsh_only
      expect(form.reload.available_languages).to eq(%w[en])
    end
  end
end
