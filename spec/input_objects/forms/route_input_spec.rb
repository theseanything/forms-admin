require "rails_helper"

RSpec.describe Forms::RouteInput, type: :model do
  subject(:route_input) { described_class.new(attributes) }

  let(:check_your_answers_value) { described_class::END_OF_FORM_VALUE }
  let(:default_value) { described_class::DEFAULT_VALUE }

  let(:page) { build_stubbed(:page) }

  let(:attributes) do
    {
      id: 1,
      page_id: 2,
      goto: 3,
      answer_value: "Yes",
      page: page,
    }
  end

  it "has a valid factory" do
    expect(build(:route_input)).to be_valid
  end

  describe "attributes" do
    it "can be initialized with a hash of attributes" do
      expect(route_input.id).to eq(1)
      expect(route_input.page_id).to eq("2")
      expect(route_input.goto).to eq(3)
      expect(route_input.answer_value).to eq("Yes")
      expect(route_input.page).to eq(page)
    end

    it "allows access to other accessors like label" do
      route_input.label = "Go to next page"
      expect(route_input.label).to eq("Go to next page")
    end
  end

  describe "#goes_to_default_next_page?" do
    context "when goto is the default value symbol" do
      it "returns true" do
        route_input.goto = default_value
        expect(route_input.goes_to_default_next_page?).to be true
      end
    end

    context "when goto is the default value string" do
      it "returns true" do
        route_input.goto = default_value.to_s
        expect(route_input.goes_to_default_next_page?).to be true
      end
    end

    context "when goto is some other value" do
      it "returns false" do
        route_input.goto = 123
        expect(route_input.goes_to_default_next_page?).to be false
      end
    end
  end

  describe "#goes_to_end_of_form?" do
    context "when goto is the check_your_answers symbol" do
      it "returns true" do
        route_input.goto = check_your_answers_value
        expect(route_input.goes_to_end_of_form?).to be true
      end
    end

    context "when goto is the check_your_answers string" do
      it "returns true" do
        route_input.goto = check_your_answers_value.to_s
        expect(route_input.goes_to_end_of_form?).to be true
      end
    end

    context "when goto is some other value" do
      it "returns false" do
        route_input.goto = 456
        expect(route_input.goes_to_end_of_form?).to be false
      end
    end
  end

  describe "#condition_attributes" do
    it "returns nil if the route is to the default next page" do
      route_input.goto = default_value
      expect(route_input.condition_attributes).to be_nil
    end

    it "returns skip_to_end: true if the route is to the end of the form" do
      route_input.goto = check_your_answers_value
      expect(route_input.condition_attributes).to eq({ goto_page_id: nil, skip_to_end: true, check_page_id: page.id, answer_value: "Yes" })
    end

    it "returns the correct attributes if the route is to a different page" do
      route_input.goto = 123
      expect(route_input.condition_attributes).to eq(
        { goto_page_id: 123, skip_to_end: false, check_page_id: page.id, answer_value: "Yes" },
      )
    end
  end
end
