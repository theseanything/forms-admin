require "rails_helper"

describe MakeFormLiveService do
  subject(:make_form_live_service) { described_class.call(current_form:, current_user:) }

  let(:current_form) { create :form, :ready_for_live }
  let(:current_user) { build :user }

  before do
    current_form.set_task_status_service(TaskStatusService.new(form: current_form, current_user:))
  end

  describe "#make_live" do
    it "makes the form live" do
      expect {
        make_form_live_service.make_live
      }.to change { current_form.reload.live_form_document_id }.from(nil)
    end

    it "does not call the SubmissionEmailMailer" do
      expect(SubmissionEmailMailer).not_to receive(:alert_email_change)
      make_form_live_service.make_live
    end

    context "when draft form has live version" do
      let(:current_form) { create :form, :live_with_draft }
      let(:live_submission_email) { current_form.live_form_document.content["submission_email"] }

      context "when submission email has not been changed" do
        it "does not call the SubmissionEmailMailer" do
          expect(SubmissionEmailMailer).not_to receive(:alert_email_change)
          make_form_live_service.make_live
        end
      end

      context "when submission email has changed" do
        before do
          current_form.submission_email = "i-have-changed@example.com"
          current_form.save_draft!
        end

        it "calls the SubmissionEmailMailer" do
          expect(SubmissionEmailMailer).to receive(:alert_email_change).with(
            live_email: live_submission_email,
            form_name: current_form.name,
            creator_name: current_user.name,
            creator_email: current_user.email,
          ).and_call_original

          make_form_live_service.make_live
        end
      end
    end
  end

  describe "#make_language_live" do
    it "publishes the form" do
      expect {
        described_class.call(current_form:, current_user:, language: "en").make_language_live
      }.to change { current_form.reload.live_form_document_id }.from(nil)
    end
  end
end
