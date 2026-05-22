require "rails_helper"

describe Pages::RoutesController, type: :request do
  let(:form) { create :form, :ready_for_routing }
  let(:pages) { form.pages }
  let(:page) do
    step = pages.first
    step.update!(
      answer_type: "selection",
      is_optional: false,
      answer_settings: {
        "only_one_option" => "true",
        "selection_options" => [{ "name" => "Option 1" }, { "name" => "Option 2" }],
      },
    )
    form.save_question_changes!
    form.reload.pages.first
  end

  let(:group) { create(:group, organisation: standard_user.organisation) }
  let(:user) { standard_user }

  before do
    Membership.create!(group_id: group.id, user: standard_user, added_by: standard_user)
    GroupForm.create!(form_id: form.id, group_id: group.id)
    login_as user
  end

  describe "#show" do
    before do
      get show_routes_path(form_id: form.id, page_id: page.id)
    end

    it "renders the routing page template" do
      expect(response).to render_template("pages/routes/show")
    end

    context "when the page is at the end of the form" do
      let(:page) do
        step = pages.last
        step.update!(
          answer_type: "selection",
          is_optional: false,
          answer_settings: {
            "only_one_option" => "true",
            "selection_options" => [{ "name" => "Option 1" }, { "name" => "Option 2" }],
          },
        )
        form.save_question_changes!
        form.reload.pages.last
      end

      it "renders the routing page template" do
        expect(response).to render_template("pages/routes/show")
      end
    end
  end

  describe "#delete" do
    before do
      get delete_routes_path(form_id: form.id, page_id: page.id)
    end

    it "renders the delete confirmation for routes template" do
      expect(response).to have_http_status(:ok)
      expect(response).to render_template("pages/routes/delete")
    end
  end

  describe "#destroy" do
    let!(:condition) { create :condition, form:, routing_page_id: page.id, check_page_id: page.id, goto_page_id: pages.last.id, answer_value: "Option 1" }
    let(:secondary_skip_page) { form.reload.pages[2] }
    let!(:secondary_skip) { create :condition, form:, routing_page_id: secondary_skip_page.id, check_page_id: page.id, goto_page_id: pages[3].id }

    context "when confirmed" do
      it "redirects to page list" do
        delete destroy_routes_path(form_id: form.id, page_id: page.id, pages_routes_delete_confirmation_input: { confirm: "yes" })
        expect(response).to redirect_to form_pages_path(form_id: form.id)
      end

      it "destroys the conditions" do
        delete destroy_routes_path(form_id: form.id, page_id: page.id, pages_routes_delete_confirmation_input: { confirm: "yes" })
        reloaded_page = form.reload.pages.find { |p| p.id == page.id }
        expect(reloaded_page.routing_conditions).to be_empty
        expect(form.reload.draft_content_service.conditions.map(&:id)).not_to include(secondary_skip.id.to_s)
      end

      context "but one of the routes is already deleted" do
        it "does not render an error page" do
          delete destroy_routes_path(form_id: form.id, page_id: page.id, pages_routes_delete_confirmation_input: { confirm: "yes" })
          expect(response).not_to be_client_error
        end
      end
    end

    context "when given invalid params" do
      it "renders the delete page" do
        delete destroy_routes_path(form_id: form.id, page_id: page.id, pages_routes_delete_confirmation_input: { confirm: nil })

        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template("pages/routes/delete")
      end
    end

    context "when not confirmed" do
      it "redirects to routes page" do
        delete destroy_routes_path(form_id: form.id, page_id: page.id, pages_routes_delete_confirmation_input: { confirm: "no" })
        expect(response).to redirect_to show_routes_path(form_id: form.id, page_id: page.id)
      end

      it "does not destroy the conditions" do
        delete destroy_routes_path(form_id: form.id, page_id: page.id, pages_routes_delete_confirmation_input: { confirm: "no" })
        reloaded_page = form.reload.pages.find { |p| p.id == page.id }
        expect(reloaded_page.routing_conditions).not_to be_empty
      end
    end
  end
end
