require "rails_helper"

RSpec.describe FormDocument::Step, type: :model do
  subject(:form_document_step) { described_class.new(page_as_form_document_step) }

  let(:form) { create(:form, pages_count: 2) }
  let(:page) { create(:page, form:, answer_type: "selection", answer_settings: { "only_one_option" => "true", "selection_options" => [{ "name" => "Yes" }] }) }
  let(:next_page) { form.pages.second }
  let(:page_as_form_document_step) { page.as_form_document_step(next_page) }

  it "ignores any attributes that are not defined" do
    expect(described_class.new(foo: "bar").attributes).not_to include(:foo)
  end

  it "has the ID, position and next page ID from the form_document_step" do
    expect(form_document_step).to have_attributes(
      id: page.external_id,
      position: page.position,
      next_step_id: next_page.external_id,
    )
  end

  it "has all question attributes the original page has" do
    expect(form_document_step).to have_attributes(answer_type: page.answer_type)
    expect(form_document_step.question_text).to eq({ "en" => page.question_text })
    expect(form_document_step.hint_text).to eq({ "en" => page.hint_text })
    expect(form_document_step.page_heading).to eq({ "en" => page.page_heading })
    expect(form_document_step.guidance_markdown).to eq({ "en" => page.guidance_markdown })
    expect(form_document_step.is_optional?).to eq(page.is_optional?)
    expect(form_document_step.is_repeatable?).to eq(page.is_repeatable?)
    if page.answer_settings.present?
      expect(form_document_step.data.answer_settings).to eq(page.answer_settings)
    end
  end

  describe "#is_optional?" do
    [
      { input: true, result: true },
      { input: "true", result: true },
      { input: false, result: false },
      { input: "false", result: false },
      { input: "0", result: false },
      { input: nil, result: false },
    ].each do |scenario|
      it "returns #{scenario[:result]} when is_optional is #{scenario[:input]}" do
        step = described_class.new("data" => { "is_optional" => scenario[:input] })
        expect(step.is_optional?).to eq scenario[:result]
      end
    end
  end

  describe "#is_repeatable?" do
    [
      { input: true, result: true },
      { input: "true", result: true },
      { input: false, result: false },
      { input: "false", result: false },
      { input: "0", result: false },
      { input: nil, result: false },
    ].each do |scenario|
      it "returns #{scenario[:result]} when is_repeatable is #{scenario[:input]}" do
        step = described_class.new("data" => { "is_repeatable" => scenario[:input] })
        expect(step.is_repeatable?).to eq scenario[:result]
      end
    end
  end

  describe "#routing_conditions" do
    it "defaults to an empty array" do
      expect(described_class.new).to have_attributes(routing_conditions: [])
    end

    it "converts attributes for routing conditions to a model" do
      routing_condition_attributes = attributes_for :condition
      step = described_class.new("routing_conditions" => [routing_condition_attributes])
      expect(step.routing_conditions).to all be_a FormDocument::Condition
    end
  end
end
