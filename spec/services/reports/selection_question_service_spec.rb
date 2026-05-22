require "rails_helper"

RSpec.describe Reports::SelectionQuestionService do
  subject(:selection_question_service) { described_class.new(form_documents) }

  describe "#statistics" do
    let(:form_documents) do
      form_1 = create(:form, :ready_for_live, pages_count: 0)
      [
        create(:page, :selection_with_autocomplete, form: form_1, is_optional: false),
        create(:page, :selection_with_autocomplete, form: form_1, is_optional: true),
        create(:page, :selection_with_radios, form: form_1, is_optional: true),
        create(:page, :selection_with_checkboxes, form: form_1, is_optional: true),
        create(:page, :selection_with_none_of_the_above_question, form: form_1, only_one_option: "true", none_of_the_above_question_is_optional: "true"),
        create(:page, :selection_with_none_of_the_above_question, form: form_1, only_one_option: "true", none_of_the_above_question_is_optional: "false"),
      ]
      FormDocumentFactoryHelpers.publish_form!(form_1)
      form_1.reload

      form_2 = create(:form, :ready_for_live, pages_count: 0)
      [
        create(:page, :selection_with_autocomplete, form: form_2, is_optional: true),
        create(:page, :selection_with_radios, form: form_2, is_optional: false),
        create(:page, :selection_with_none_of_the_above_question, form: form_2, only_one_option: "true", none_of_the_above_question_is_optional: "false"),
      ]
      FormDocumentFactoryHelpers.publish_form!(form_2)
      form_2.reload

      [
        FormDocumentFactoryHelpers.report_form_document_json(form_1),
        FormDocumentFactoryHelpers.report_form_document_json(form_2),
      ]
    end

    it "returns statistics" do
      response = selection_question_service.statistics
      expect(response[:autocomplete][:form_ids].length).to be 2
      expect(response[:autocomplete][:question_count]).to be 3
      expect(response[:autocomplete][:optional_question_count]).to be 2
      expect(response[:radios][:form_ids].length).to be 2
      expect(response[:radios][:question_count]).to be 5
      expect(response[:radios][:optional_question_count]).to be 4
      expect(response[:checkboxes][:form_ids].length).to be 1
      expect(response[:checkboxes][:optional_question_count]).to be 1
      expect(response[:include_none_of_the_above][:form_ids].length).to be 2
      expect(response[:include_none_of_the_above][:question_count]).to be 7
      expect(response[:include_none_of_the_above][:with_follow_up_question][:form_ids].length).to be 2
      expect(response[:include_none_of_the_above][:with_follow_up_question][:question_count]).to be 3
      expect(response[:include_none_of_the_above][:with_follow_up_question][:mandatory_follow_up_question_count]).to be 2
      expect(response[:include_none_of_the_above][:with_follow_up_question][:optional_follow_up_question_count]).to be 1
    end
  end
end
