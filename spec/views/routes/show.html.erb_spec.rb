require "rails_helper"

describe "routes/show.html.erb" do
  let(:form) { create(:form, pages_count: 3) }
  let(:pages) { form.pages }
  let(:routes_input) { build(:routes_input, form:).assign_form_values }

  def render_page
    assign(:current_form, form)
    assign(:routes_input, routes_input)
    render template: "routes/show", locals: { current_form: form, routes_input: }
  end

  it "has the correct title" do
    render_page
    expect(view.content_for(:title)).to have_content("Edit question routes")
  end

  it "has the correct back link" do
    render_page
    expect(view.content_for(:back_link)).to have_link("Back to your form", href: form_pages_path(form.id))
  end

  it "has the correct heading and caption" do
    render_page
    expect(rendered).to have_selector("h1", text: form.name)
    expect(rendered).to have_selector("h1", text: "Edit question routes")
  end

  context "when the form has pages and routes" do
    before do
      create(:condition, form:, routing_page_id: pages.first.id, check_page_id: pages.first.id, answer_value: nil, goto_page_id: pages.third.id)
      form.reload
    end

    it "has a summary list with a row for each page" do
      render_page
      expect(rendered).to have_selector(".govuk-summary-list") do |summary_list|
        expect(summary_list).to have_selector(".govuk-summary-list__row", count: pages.length)
      end
    end

    it "displays the page's position and question text" do
      render_page
      expect(rendered).to have_selector(".govuk-summary-list__key", text: pages.first.position.to_s)
      expect(rendered).to have_selector(".govuk-summary-list__value", text: pages.first.question_text)
    end

    it "includes the page's position in the id of the key" do
      render_page
      expect(rendered).to have_selector("#page-#{pages.first.position}")
    end

    it "has a select field for each page except the last one" do
      render_page
      expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][0][goto]"]')
      expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][1][goto]"]')
      expect(rendered).not_to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][2][goto]"]')
    end

    it "has options for where the route should go to for each select field" do
      render_page

      def select_options(select_field)
        select_field.find_all("option").map { [it["value"], it.text] }
      end

      expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][0][goto]"]') do |field|
        expect(select_options(field)).to eq [
          ["default", "Go to question 2"],
          [pages.third.id.to_s, "3. #{pages.third.question_text}"],
          ["end_of_form", "End of the form"],
        ]
      end

      expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][1][goto]"]') do |field|
        expect(select_options(field)).to eq [
          ["default", "Go to question 3"],
          ["end_of_form", "End of the form"],
        ]
      end
    end

    it "shows the selected goto page for the route" do
      render_page

      expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][0][goto]"]') do |field|
        expect(field).to have_selector("option[selected]") do |option|
          expect(option["value"]).to eq pages.third.id.to_s
        end
      end

      expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][1][goto]"]') do |field|
        expect(field).to have_selector("option[selected]") do |option|
          expect(option["value"]).to eq "default"
        end
      end
    end

    context "when the route goes to a page before the routing page" do
      before do
        create(:condition, form:, routing_page_id: pages.second.id, check_page_id: pages.second.id, answer_value: nil, goto_page_id: pages.first.id)
        form.reload
      end

      it "shows the selected goto page for the route" do
        render_page

        expect(rendered).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][1][goto]"]') do |field|
          expect(field).to have_selector("option[selected]") do |option|
            expect(option["value"]).to eq pages.first.id.to_s
          end
        end
      end
    end

    context "when a page is a select from a list question" do
      let(:selection_options) do
        [{ "name" => "Yes", "value" => "Yes" }, { "name" => "No", "value" => "No" }]
      end

      let(:form) do
        create(:form).tap do |f|
          hash = f.draft_content_service.content_hash
          hash["steps"] = [
            FormDocumentFactoryHelpers.build_step_attrs(
              position: 1,
              answer_type: "selection",
              answer_settings: { "only_one_option" => "true", "selection_options" => selection_options },
            ),
            FormDocumentFactoryHelpers.build_step_attrs(position: 2),
            FormDocumentFactoryHelpers.build_step_attrs(position: 3),
          ]
          hash["steps"].each_with_index { |s, i| s["next_step_id"] = hash["steps"][i + 1]&.dig("id") }
          hash["start_page"] = hash["steps"].first["id"]
          FormDocumentOperationsService.new(f).save_draft_content!(hash)
        end
      end

      it "has inputs for each answer option" do
        render_page

        expect(rendered).to have_selector(".govuk-summary-list") do |summary_list|
          rows = summary_list.find_all(".govuk-summary-list__row")

          expect(rows[0]).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][0][goto]"]')
          expect(rows[0]).to have_selector("input[name=\"forms_routes_input[routes_attributes][0][page_id]\"][value=\"#{pages.first.id}\"]", visible: :hidden)
          expect(rows[0]).to have_selector('input[name="forms_routes_input[routes_attributes][0][answer_value]"][value="Yes"]', visible: :hidden)

          expect(rows[0]).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][1][goto]"]')
          expect(rows[0]).to have_selector("input[name=\"forms_routes_input[routes_attributes][1][page_id]\"][value=\"#{pages.first.id}\"]", visible: :hidden)
          expect(rows[0]).to have_selector('input[name="forms_routes_input[routes_attributes][1][answer_value]"][value="No"]', visible: :hidden)

          expect(rows[1]).to have_selector('.govuk-select[name="forms_routes_input[routes_attributes][2][goto]"]')
          expect(rows[1]).to have_selector("input[name=\"forms_routes_input[routes_attributes][2][page_id]\"][value=\"#{pages.second.id}\"]", visible: :hidden)

          expect(rows[2]).not_to have_selector(".govuk-select")
        end
      end

      context "with more than 10 options" do
        let(:selection_options) do
          (1..11).map do |i|
            { "name" => "Option #{i}", "value" => "Option #{i}" }
          end
        end

        it "has one route input for that question" do
          render_page

          expect(rendered).to have_selector(".govuk-summary-list") do |summary_list|
            rows = summary_list.find_all(".govuk-summary-list__row")

            expect(rows[0]).to have_selector(".govuk-select", count: 1)
            expect(rows[1]).to have_selector(".govuk-select", count: 1)
            expect(rows[2]).not_to have_selector(".govuk-select")
          end
        end

        it "has content explaining that routes cannot be added" do
          render_page

          expected_content = <<~TEXT
            This question has a list with more than 10 options.

            You cannot add routes from answers if the question has more than 10 options.
          TEXT

          expect(rendered).to have_selector(".govuk-summary-list") do |summary_list|
            rows = summary_list.find_all(".govuk-summary-list__row")

            expect(rows[0]).to have_text(expected_content)
            expect(rows[1]).not_to have_text(expected_content)
            expect(rows[2]).not_to have_text(expected_content)
          end
        end
      end
    end
  end

  context "when there are not enoough pages" do
    let(:form) { create(:form, pages_count: 1) }

    it "shows a warning" do
      render_page
      expect(rendered).to have_content("You need more than one question in your form before you can add any routes.")
    end

    it "shows a link to the question pages" do
      render_page
      expect(rendered).to have_link("Back to your questions", href: form_pages_path(form.id))
    end
  end
end
