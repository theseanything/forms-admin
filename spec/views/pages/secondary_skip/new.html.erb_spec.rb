require "rails_helper"

describe "pages/secondary_skip/new.html.erb" do
  let(:form) { create :form, pages: [page] }
  let(:page) do
    page = build(
      :page,
      :with_selection_settings,
      id: 1,
      position: 1,
      answer_settings: DataStruct.new(
        only_one_option: true,
        selection_options: [
          OpenStruct.new(attributes: { name: "Option 1" }),
          OpenStruct.new(attributes: { name: "Option 2" }),
        ],
      ),
    )
    page.routing_conditions = [
      build(:condition, id: 1, routing_page: page, check_page: page, answer_value: "Yes", goto_page_id: 2, skip_to_end: false),
    ]
    page
  end

  let(:secondary_skip_input) { Pages::SecondarySkipInput.new(form:, page:) }

  before do
    render template: "pages/secondary_skip/new", locals: { back_link_url: "/back", secondary_skip_input: }
  end

  it "has the correct title" do
    expect(view.content_for(:title)).to have_content(I18n.t("page_titles.new_secondary_skip", route_index: 2))
  end

  it "has the correct back link" do
    expect(view.content_for(:back_link)).to have_link(I18n.t("secondary_skip.new.back", question_number: 1), href: "/back")
  end

  it "has the correct heading and caption" do
    expect(rendered).to have_selector("h1", text: "Question 1’s routes")
    expect(rendered).to have_selector("h1", text: I18n.t("page_titles.new_secondary_skip", route_index: 2))
  end

  context "when the condition is for a 'none of the above' answer" do
    let(:page) do
      page = build(
        :page,
        :with_selection_settings,
        id: 1,
        position: 1,
        answer_settings: DataStruct.new(
          only_one_option: true,
          selection_options: [
            OpenStruct.new(attributes: { name: "Option 1" }),
            OpenStruct.new(attributes: { name: "Option 2" }),
          ],
        ),
      )
      page.routing_conditions = [
        build(:condition, id: 1, routing_page: page, check_page: page, goto_page_id: 2, skip_to_end: false, answer_value: Condition::NONE_OF_THE_ABOVE),
      ]
      page
    end

    it "has the correct answer value text" do
      expect(rendered).to have_selector(".govuk-summary-list__row") do |row|
        row.has_css?(".govuk-summary-list__key", exact_text: "If the answer is") &&
          row.has_css?(".govuk-summary-list__value", exact_text: "None of the above")
      end
    end
  end
end
