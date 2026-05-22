require "rails_helper"

describe Reports::AddAnotherAnswerUsageService do
  subject(:features_report_service) { described_class.new }

  describe "#add_another_answer_forms" do
    let!(:draft_step) do
      FormDocumentFactoryHelpers.build_step_attrs(position: 1, answer_type: "name", is_repeatable: true)
    end
    let!(:add_another_answer_draft_form) do
      form = create(:form)
      hash = form.draft_content_service.content_hash
      hash["steps"] = [draft_step]
      hash["start_page"] = draft_step["id"]
      FormDocumentOperationsService.new(form).save_draft_content!(hash)
      form.reload
    end

    let!(:live_steps) do
      [
        FormDocumentFactoryHelpers.build_step_attrs(position: 1, answer_type: "name", is_repeatable: true),
        FormDocumentFactoryHelpers.build_step_attrs(position: 2, answer_type: "text", is_repeatable: true),
      ].tap do |steps|
        steps.first["next_step_id"] = steps.second["id"]
      end
    end
    let!(:add_another_answer_live_form) do
      form = create(:form, :ready_for_live)
      hash = form.draft_content_service.content_hash
      hash["steps"] = live_steps
      hash["start_page"] = live_steps.first["id"]
      FormDocumentOperationsService.new(form).save_draft_content!(hash)
      FormDocumentFactoryHelpers.create_live_form!(form)
      form.reload
    end

    it "obtains all forms in the add another answer report" do
      report = features_report_service.add_another_answer_forms

      expect(report[:forms]).to contain_exactly(
        OpenStruct.new(
          form_id: add_another_answer_draft_form.id,
          name: add_another_answer_draft_form.name,
          state: add_another_answer_draft_form.lifecycle_status.to_s,
          repeatable_pages: [
            OpenStruct.new(
              page_id: draft_step["id"],
              question_text: TranslatableString.for_locale(draft_step["question_text"], locale: :en),
            ),
          ],
        ),
        OpenStruct.new(
          form_id: add_another_answer_live_form.id,
          name: add_another_answer_live_form.name,
          state: add_another_answer_live_form.lifecycle_status.to_s,
          repeatable_pages: [
            OpenStruct.new(
              page_id: live_steps.first["id"],
              question_text: TranslatableString.for_locale(live_steps.first["question_text"], locale: :en),
            ),
            OpenStruct.new(
              page_id: live_steps.second["id"],
              question_text: TranslatableString.for_locale(live_steps.second["question_text"], locale: :en),
            ),
          ],
        ),
      )
    end

    it "returns the count" do
      report = features_report_service.add_another_answer_forms
      expect(report[:count]).to eq 2
    end
  end
end
