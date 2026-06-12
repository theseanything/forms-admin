require "rails_helper"

RSpec.describe Forms::RouteInput, type: :model do
  subject(:route_input) { described_class.new(attributes) }

  let(:check_your_answers_value) { described_class::END_OF_FORM_VALUE }
  let(:default_value) { described_class::DEFAULT_VALUE }

  let(:page) { build_stubbed(:page, position: 1) }
  let(:goto_page) { build_stubbed(:page, position: 2) }

  let(:attributes) do
    {
      id: 1,
      page_id: 2,
      goto: goto_page.id,
      answer_value: "Yes",
      page: page,
      goto_page: goto_page,
    }
  end

  it "has a valid factory" do
    expect(build(:route_input)).to be_valid
  end

  describe "attributes" do
    it "can be initialized with a hash of attributes" do
      expect(route_input.id).to eq(1)
      expect(route_input.page_id).to eq(2)
      expect(route_input.goto).to eq(goto_page.id)
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
      expect(route_input.condition_attributes).to eq({ goto_page_id: nil, skip_to_end: true, check_page_id: page.id })
    end

    it "returns the correct attributes if the route is to a different page" do
      route_input.goto = 123
      expect(route_input.condition_attributes).to eq(
        { goto_page_id: 123, skip_to_end: false, check_page_id: page.id },
      )
    end
  end

  describe "#route_is_not_backwards" do
    context "when the route is not backwards" do
      let(:page) { build_stubbed(:page, position: 1) }
      let(:goto_page) { build_stubbed(:page, position: 2) }

      it "does not add an error" do
        expect(route_input).to be_valid
      end
    end

    context "when the route is backwards" do
      let(:page) { build_stubbed(:page, position: 2) }
      let(:goto_page) { build_stubbed(:page, position: 1) }

      it "adds the correct error" do
        expect(route_input).to be_invalid
        expect(route_input.errors[:goto]).to eq(["The route from question 2 cannot go to a previous question - edit this route"])
      end

      context "when the route is for a selection question" do
        let(:page) { build_stubbed(:page, :with_selection_settings, position: 2) }
        let(:attributes) { super().merge(answer_value: "Option 1") }

        it "adds the correct error" do
          expect(route_input).to be_invalid
          expect(route_input.errors[:goto]).to eq(["The route from question 2, option 1 cannot go to a previous question - edit this route"])
        end
      end

      it "doesn't add an error for a default route" do
        route_input.goto = default_value
        expect(route_input).to be_valid
      end

      it "doesn't add an error for an end of form route" do
        route_input.goto = check_your_answers_value
        expect(route_input).to be_valid
      end

      it "doesn't add an error when not goto_page is set" do
        route_input.goto_page = nil
        expect(route_input).to be_valid
      end
    end
  end
end
