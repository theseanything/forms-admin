require "rails_helper"

RSpec.describe NormaliseConditionsService do
  subject(:service) { described_class.new(form:) }

  let(:form) { create :form, :ready_for_routing }
  let(:conditions) { [] }

  before do
    conditions
    form.reload
  end

  describe "#normalise_conditions" do
    context "when form has no conditions" do
      it "does nothing" do
        expect { service.normalise_conditions }.not_to raise_error
      end
    end

    context "when form has conditions with no routing errors" do
      let(:conditions) do
        [
          create(
            :condition,
            check_page: form.pages.first,
            routing_page: form.pages.first,
            goto_page: form.pages.third,
            answer_value: "Option 1",
          ),
        ]
      end

      it "does not raise an error" do
        expect { service.normalise_conditions }.not_to raise_error
      end

      it "does nothing" do
        expect {
          service.normalise_conditions
        }.not_to change(Condition, :count)
        expect(form).not_to have_routing_errors
      end
    end

    context "when form has conditions with route to next page routing errors" do
      let(:conditions) do
        [
          create(
            :condition,
            check_page: form.pages.first,
            routing_page: form.pages.first,
            goto_page: form.pages.second,
            answer_value: "Option 1",
          ),
          create(
            :condition,
            check_page: form.pages.first,
            routing_page: form.pages.first,
            goto_page: form.pages.third,
            answer_value: "Option 2",
          ),
          create(
            :condition,
            check_page: form.pages.third,
            routing_page: form.pages.third,
            goto_page: form.pages.fourth,
            answer_value: "Option 2",
          ),
        ]
      end

      it "fixes the routing errors" do
        expect {
          service.normalise_conditions
        }.to change(form, :has_routing_errors?).from(true).to(false)
      end

      it "deletes the conditions that route to the next page" do
        expect {
          service.normalise_conditions
        }.to change(Condition, :count).by(-2)
      end

      it "does not delete conditions that do not route to the next page" do
        service.normalise_conditions

        expect(Condition.exists?(
                 routing_page: form.pages.first,
                 goto_page: form.pages.third,
               )).to be true
      end
    end

    context "when form has conditions with other validation errors" do
      let(:conditions) do
        [
          # Condition that routes to next page
          create(
            :condition,
            check_page: form.pages.first,
            routing_page: form.pages.first,
            goto_page: form.pages.second,
            answer_value: "Option 1",
          ),
          # Valid condition
          create(
            :condition,
            check_page: form.pages.first,
            routing_page: form.pages.first,
            goto_page: form.pages.third,
            answer_value: "Option 2",
          ),
          # Condition that has an invalid answer_value
          create(
            :condition,
            check_page: form.pages.first,
            routing_page: form.pages.first,
            goto_page: form.pages.third,
            answer_value: "Not an option",
          ),
          # Condition that routes backwards
          create(
            :condition,
            check_page: form.pages.third,
            routing_page: form.pages.third,
            goto_page: form.pages.first,
            answer_value: "Option 1",
          ),
          # Condition that routes to next page and has an invalid answer_value
          create(
            :condition,
            check_page: form.pages.third,
            routing_page: form.pages.third,
            goto_page: form.pages.fourth,
            answer_value: "Not an option",
          ),
        ]
      end

      it "does not raise an error" do
        expect { service.normalise_conditions }.not_to raise_error
      end

      it "does nothing" do
        expect {
          service.normalise_conditions
        }.not_to change(Condition, :count)
        expect(form).to have_routing_errors
      end
    end
  end
end
