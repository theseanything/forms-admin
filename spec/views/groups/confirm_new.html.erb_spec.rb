require "rails_helper"

RSpec.describe "groups/confirm_new", type: :view do
  let(:organisation) { build(:organisation) }
  let(:confirm_new_input) { Groups::ConfirmNewInput.new }

  before do
    assign(:confirm_new_input, confirm_new_input)
    assign(:organisation, organisation)
    render
  end

  it "contains the page heading" do
    expect(rendered).to have_css("h1", text: I18n.t("page_titles.group_confirm_new"))
  end

  it "contains a back link" do
    expect(view.content_for(:back_link)).to have_link(I18n.t("back_link.groups"), href: groups_path)
  end

  it "renders the new group form" do
    assert_select "form[action=?][method=?]", confirm_new_groups_path, "post"
  end

  it "includes a radio button for selecting yes" do
    expect(rendered).to have_unchecked_field(I18n.t("helpers.label.confirm_action_input.options.yes"))
  end

  it "includes the body text for a group without an admin user" do
    expect(rendered).to include(I18n.t("groups.confirm_new.without_org_admin.body_html"))
  end

  context "when the organisation has an admin user" do
    let(:organisation) { create(:organisation, :with_org_admin) }

    it "includes the body text for a group with an admin user" do
      expect(rendered).to include(I18n.t("groups.confirm_new.with_org_admin.body_html"))
    end

    it "includes the list of admin users" do
      expect(rendered).to include(I18n.t("groups.confirm_new.with_org_admin.org_admin_list_title"))
      expect(rendered).to have_text(organisation.admin_users.first.email)
    end
  end
end
