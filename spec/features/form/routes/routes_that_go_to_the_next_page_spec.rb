require "rails_helper"

RSpec.describe "Questions are moved or deleted such that a route becomes a default route", :feature_multiple_branches, type: :feature do
  let(:organisation) { standard_user.organisation }
  let(:group) { create :group, organisation: }
  let(:user) { standard_user }

  let(:form) { create :form, :ready_for_routing }

  before do
    group.update! multiple_branches_enabled: true
    GroupForm.create! group:, form_id: form.id
    create :membership, group:, user:, added_by: user

    login_as user
  end

  scenario "Moving pages such that a route becomes a default route does not cause validation errors" do
    routing_page = form.pages.first
    goto_page = form.pages.third

    # Given the form has a skip route
    Condition.create! check_page: routing_page, routing_page:, goto_page:, answer_value: "Option 1"

    # When I am editing the form's questions
    visit form_pages_path(form)

    # And I move the goto page to be next after the routing page
    move_up_button = find :button, text: "Move up", value: goto_page.id
    move_up_button.click
    expect(page).to have_css ".govuk-notification-banner", text: /has moved up/

    # Then I shouldn't see any validation errors
    expect(page).not_to have_css ".govuk-error-summary"
    expect(page).not_to have_css ".govuk-error"

    # And I can save my questions
    click_button text: "Save"
    expect(page).to have_css ".govuk-notification-banner", text: "Your questions have been saved"
  end

  scenario "Routes that match the default route are deleted when the form creator has finished editing their questions" do
    routing_page = form.pages.first
    goto_page = form.pages.third

    # Given the form has a skip route
    create :condition, check_page: routing_page, routing_page:, goto_page:, answer_value: "Option 1"

    # When I am editing the form's questions
    visit form_pages_path(form)

    # And I move the goto page to be next after the routing page
    move_up_button = find :button, text: "Move up", value: goto_page.id
    move_up_button.click
    expect(page).to have_css ".govuk-notification-banner", text: /has moved up/

    # When I answer yes to "Have you finished editing your questions?"
    choose "Yes"
    click_button text: "Save"
    expect(page).to have_css ".govuk-notification-banner", text: "Your questions have been saved"

    # Then the skip route is deleted
    expect(Condition).not_to exist(routing_page:, goto_page:, answer_value: "Option 1")
  end

  scenario "Routes that match the default route are deleted when the routes are saved" do
    routing_page = form.pages.first
    goto_page = form.pages.third

    # Given the form has a skip route
    create :condition, check_page: routing_page, routing_page:, goto_page:, answer_value: "Option 1"

    # When I am editing the form's questions
    visit form_pages_path(form)

    # And I move the goto page to be next after the routing page
    move_up_button = find :button, text: "Move up", value: goto_page.id
    move_up_button.click
    expect(page).to have_css ".govuk-notification-banner", text: /has moved up/

    # When I go to the edit routes page
    visit routes_path(form)
    expect(page).to have_title "Edit question routes"

    # And save the routes
    click_button text: "Save"
    expect(page).to have_css ".govuk-notification-banner", text: "Your routes have been saved"

    # Then the skip route is deleted
    expect(Condition).not_to exist(routing_page:, goto_page:, answer_value: "Option 1")
  end
end
