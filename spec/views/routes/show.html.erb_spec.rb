require "rails_helper"

describe "routes/show.html.erb" do
  let(:form) { build_stubbed :form, pages: }
  let(:pages) { [] }
  let(:routes) { [] }
  let(:routes_input) { build :routes_input, form:, routes: }

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
    let(:pages) { build_stubbed_list(:page, 3) }
    let(:routes) do
      [
        build(:route_input, page: pages.first, goto: pages.third.id, goto_options: []),
        build(:route_input, :default, page: pages.second, goto_options: []),
        build(:route_input, :default, page: pages.third, goto_options: []),
      ]
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
  end
end
