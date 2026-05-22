require "rails_helper"

RSpec.describe FormDocument::Condition, type: :model do
  subject(:form_document_condition) { described_class.new(condition_as_form_document_condition) }

  let(:condition) { create :condition }
  let(:condition_as_form_document_condition) { condition.as_form_document_condition }

  it "ignores any attributes that are not defined" do
    expect(described_class.new(foo: "bar").attributes).not_to include(:foo)
  end

  it "has all the attributes the original condition has" do
    doc_attrs = form_document_condition.attributes.except("routing_page_id", "validation_errors", "created_at", "updated_at")
    condition_attrs = condition.as_form_document_condition.except("routing_page_id").transform_values { |v| v.is_a?(Integer) ? v.to_s : v }
    normalized_doc_attrs = doc_attrs.transform_values { |v| v.is_a?(Integer) ? v.to_s : v }
    expect(normalized_doc_attrs).to include(condition_attrs)
    expect(form_document_condition.routing_page_id).to eq(condition.routing_page_id.to_s)
  end

  it "has a validation_errors attribute" do
    expect(form_document_condition.validation_errors).to be_an(Array)
    expect(condition.validation_errors).to be_an(Array)
  end

  it_behaves_like "implements condition methods"
end
