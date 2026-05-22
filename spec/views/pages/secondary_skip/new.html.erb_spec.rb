require "rails_helper"

describe "pages/secondary_skip/new.html.erb" do
  let(:form) { create(:form, :ready_for_routing) }
  let!(:primary_route) do
    create(:condition, form:, routing_page_id: form.pages.first.id, check_page_id: form.pages.first.id, answer_value: "Option 1", goto_page_id: form.pages.third.id)
  end
  let(:page) { form.reload.pages.first }
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
end
