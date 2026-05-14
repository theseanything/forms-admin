require "rails_helper"

RSpec.describe Forms::CopyOfAnswersInput, type: :model do
  let(:form) { create(:form, send_copy_of_answers:) }
  let(:send_copy_of_answers) { "disabled" }

  describe "validation" do
    it "is valid when send_copy_of_answers is 'enabled'" do
      expect(described_class.new(form:, send_copy_of_answers: "enabled")).to be_valid
    end

    it "is valid when send_copy_of_answers is 'disabled'" do
      expect(described_class.new(form:, send_copy_of_answers: "disabled")).to be_valid
    end

    it "is invalid when send_copy_of_answers is not allowed value" do
      expect(described_class.new(form:, send_copy_of_answers: "invalid")).not_to be_valid
    end

    it "is invalid when send_copy_of_answers is nil" do
      expect(described_class.new(form: form, send_copy_of_answers: nil)).not_to be_valid
    end
  end

  describe "#submit" do
    subject(:input) { described_class.new(form:, send_copy_of_answers: value) }

    context "when enabling" do
      let(:send_copy_of_answers) { "disabled" }
      let(:value) { "enabled" }

      it "updates the form send_copy_of_answers flag to 'enabled'" do
        expect { input.submit }.to change { form.reload.send_copy_of_answers }.to(value)
      end
    end

    context "when disabling" do
      let(:send_copy_of_answers) { "enabled" }
      let(:value) { "disabled" }

      it "updates the form send_copy_of_answers flag to 'disabled'" do
        expect { input.submit }.to change { form.reload.send_copy_of_answers }.to(value)
      end
    end

    context "when send_copy_of_answers is invalid" do
      let(:value) { "invalid" }

      it "returns false and does not update the form" do
        expect(input.submit).to be false
        expect(form.reload.send_copy_of_answers).to eq("disabled")
      end
    end
  end

  describe "#assign_form_values" do
    subject(:input) { described_class.new(form:) }

    let(:send_copy_of_answers) { "enabled" }

    it "sets the send_copy_of_answers value from the form" do
      input.assign_form_values

      expect(input.send_copy_of_answers).to eq("enabled")
    end
  end
end
