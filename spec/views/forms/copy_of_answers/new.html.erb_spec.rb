require "rails_helper"

describe "forms/copy_of_answers/new.html.erb" do
  let(:form) { build(:form, id: 1, send_copy_of_answers:) }
  let(:send_copy_of_answers) { "enabled" }
  let(:copy_of_answers_input) { Forms::CopyOfAnswersInput.new(form:).assign_form_values }

  before do
    assign(:copy_of_answers_input, copy_of_answers_input)
    render
  end

  it "sets the page title" do
    expect(view.content_for(:title)).to eq(t("page_titles.copy_of_answers"))
  end

  it "has the correct heading" do
    expect(rendered).to have_css("h1", text: t("page_titles.copy_of_answers"))
  end

  it "includes the expected body text" do
    expect(rendered).to include(t("forms.copy_of_answers.new.body_html"))
  end

  it "includes the expected fieldset legend" do
    expect(rendered).to have_css("legend", text: "Do you want to give people the option to get a copy of their answers by email?")
  end

  it "has a checkbox with a checked value of enabled" do
    expect(rendered).to have_css("input[type='checkbox'][name='forms_copy_of_answers_input[send_copy_of_answers]'][value='enabled']")
  end

  it "has a hidden input with a value of disabled, used when the checkbox isn't checked" do
    expect(rendered).to have_css("input[name='forms_copy_of_answers_input[send_copy_of_answers]'][value='disabled']", visible: :hidden)
  end

  it "includes the expected checkbox label" do
    expect(rendered).to have_css(".govuk-label[for='forms-copy-of-answers-input-send-copy-of-answers-enabled-field']", text: "Give people the option to get a copy of their answers by email - I’m ok with the risk")
  end

  context "when the form has send_copy_of_answers set to 'enabled'" do
    let(:send_copy_of_answers) { "enabled" }

    it "renders the checkbox as checked" do
      expect(rendered).to have_checked_field("forms-copy-of-answers-input-send-copy-of-answers-enabled-field")
    end
  end

  context "when the form has send_copy_of_answers set to 'disabled" do
    let(:send_copy_of_answers) { "disabled" }

    it "renders the checkboxes as unchecked" do
      expect(rendered).to have_unchecked_field("forms-copy-of-answers-input-send-copy-of-answers-enabled-field")
    end
  end
end
