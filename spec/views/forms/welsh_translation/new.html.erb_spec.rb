require "rails_helper"

describe "forms/welsh_translation/new.html.erb" do
  let(:form) { build_form }
  let(:page) { form.pages.first }
  let(:another_page) { form.pages.second }
  let(:welsh_page_translation_input) { Forms::WelshPageTranslationInput.new(page:).assign_page_values }
  let(:another_welsh_page_translation_input) { Forms::WelshPageTranslationInput.new(page: another_page).assign_page_values }
  let(:welsh_translation_input) { Forms::WelshTranslationInput.new(form:, page_translations: [welsh_page_translation_input, another_welsh_page_translation_input]).assign_form_values }
  let(:table_presenter) { Forms::TranslationTablePresenter.new }
  let(:mark_complete) { "true" }
  let(:welsh_translation_delete_path) { "/welsh-translation/delete" }
  let(:welsh_translation_download_path) { "/welsh-translation/download" }
  let(:has_welsh_translation?) { false }

  def build_welsh_translation_input
    page_translations = form.pages.map { |p| Forms::WelshPageTranslationInput.new(page: p).assign_page_values }
    Forms::WelshTranslationInput.new(form:, page_translations:).assign_form_values
  end

  def render_welsh_translation_form
    assign(:welsh_translation_input, build_welsh_translation_input.tap { |input| input.mark_complete = mark_complete })
    render
  end

  def build_form(attributes = {})
    default_attributes = {
      name: "My form",
      name_cy: "My Welsh form",
      what_happens_next_markdown: "English what happens next",
      what_happens_next_markdown_cy: "Welsh what happens next",
      privacy_policy_url: "https://www.gov.uk/privacy",
      privacy_policy_url_cy: "https://www.gov.uk/privacy_cy",
      payment_url: "https://www.gov.uk/payment",
      payment_url_cy: "https://www.gov.uk/payment_cy",
      support_email: "support@example.gov.uk",
      support_phone: "English support phone",
      support_url: "https://www.gov.uk/support",
      support_url_text: "Support URL text",
      declaration_markdown: "Declaration markdown",
      pages_count: 2,
    }
    attrs = default_attributes.merge(attributes)
    cy_fields = attrs.extract!(*Form::TRANSLATABLE_CY_FIELDS.map { |field| :"#{field}_cy" })
    support_phone = attrs.delete(:support_phone)
    support_url = attrs.delete(:support_url)
    support_url_text = attrs.delete(:support_url_text)

    create(:form, attrs).tap do |form|
      hash = form.draft_content_service.content_hash
      hash["support_phone"] = { "en" => support_phone } if support_phone.present?
      hash["support_url"] = { "en" => support_url } if support_url.present?
      hash["support_url_text"] = { "en" => support_url_text } if support_url_text.present?
      FormDocumentOperationsService.new(form).save_draft_content!(hash) if support_phone.present? || support_url.present? || support_url_text.present?
      cy_fields.each do |attr, value|
        form.public_send("#{attr}=", value) if value.present?
      end
    end
  end

  before do
    welsh_translation_input.mark_complete = mark_complete
    allow(view).to receive_messages(welsh_translation_delete_path:, welsh_translation_download_path:)
    allow(form).to receive(:has_welsh_translation?).and_return(has_welsh_translation?)
    assign(:table_presenter, table_presenter)
  end

  context "when the form has no errors" do
    before { render_welsh_translation_form }

    it "contains page heading and sub-heading" do
      expect(rendered).to have_css("h1 .govuk-caption-l", text: form.name)
      expect(rendered).to have_css("h1.govuk-heading-l", text: "Add a Welsh version of your form")
    end

    it "contains a link to preview the Welsh form" do
      expect(rendered).to have_link(t("forms.welsh_translation.new.preview_link_text"), href: preview_link(form, locale: :cy))
    end

    it "renders a text input for 'Form name'" do
      expect(rendered).to have_field("Enter your Welsh form name", type: "text", with: "My Welsh form")
    end

    it "renders english text for 'Form name'" do
      expect(rendered).to have_text("My form")
    end

    it "renders a text area for 'Declaration'" do
      expect(rendered).to have_field("Enter your Welsh declaration", type: "textarea", with: nil)
    end

    it "renders english text for 'Declaration'" do
      expect(rendered).to have_text("Declaration markdown")
    end

    it "renders a text area for 'What happens next'" do
      expect(rendered).to have_field("Enter information about what happens next in Welsh", type: "textarea", with: "Welsh what happens next")
    end

    it "renders english text for 'What happens next'" do
      expect(rendered).to have_text("English what happens next")
    end

    it "renders a text input for 'Privacy policy URL'" do
      expect(rendered).to have_field("Enter link to your Welsh privacy information", type: "text", with: "https://www.gov.uk/privacy_cy")
    end

    it "renders english text for 'Privacy policy URL'" do
      expect(rendered).to have_text("https://www.gov.uk/privacy")
    end

    it "renders a text input for 'Link to a payment page'" do
      expect(rendered).to have_field("Enter Welsh GOV.UK Pay payment link", type: "text", with: "https://www.gov.uk/payment_cy")
    end

    it "renders english text for 'Link to a payment page'" do
      expect(rendered).to have_text("https://www.gov.uk/payment")
    end

    it "renders text inputs for all the support contact fields" do
      expect(rendered).to have_field("Enter email address for Welsh support", type: "email")
      expect(rendered).to have_field("Enter phone information for Welsh support", type: "textarea")
      expect(rendered).to have_field("Enter an online contact link for Welsh support", type: "text")
      expect(rendered).to have_field("Enter text to describe the contact link for Welsh support", type: "text")
    end

    it "renders english text for support contact fields" do
      expect(rendered).to have_text("support@example.gov.uk")
      expect(rendered).to have_text("English support phone")
      expect(rendered).to have_text("https://www.gov.uk/support")
      expect(rendered).to have_text("Support URL text")
    end

    it "renders radio buttons for 'finished adding your Welsh version?'" do
      expect(rendered).to have_css("legend", text: "Have you finished adding your Welsh version?")
      expect(rendered).to have_field("Yes", type: "radio")
      expect(rendered).to have_field("No", type: "radio")
    end

    it "renders a 'Save and continue' button" do
      expect(rendered).to have_button("Save and continue")
    end

    it "does not render a link to delete the translation" do
      expect(rendered).not_to have_link(href: welsh_translation_delete_path)
    end

    it "renders all of the translation form fields with the welsh lang attribute" do
      form_fields = Capybara.string(rendered).find_all(".app-translation-table .govuk-form-group")

      expect(form_fields).not_to be_empty

      expect(form_fields).to all(have_css("[lang='cy']"))
    end

    it "renders a button to download the form as a CSV" do
      expect(rendered).to have_link(t("forms.welsh_translation.new.csv_download"), href: welsh_translation_download_path)
    end

    context "when the form already has a Welsh translation" do
      let(:has_welsh_translation?) { true }

      it "renders a link to delete the translation" do
        expect(rendered).to have_link(t("forms.welsh_translation.new.delete_welsh_version"), href: welsh_translation_delete_path, class: "govuk-button--warning")
      end
    end

    context "when the form does not have a declaration markdown" do
      let(:form) { build_form(declaration_markdown: nil) }

      it "does not render a declaration text area" do
        expect(rendered).not_to have_field("Declaration", type: "textarea")
      end

      it "renders message for no declaration text" do
        expect(rendered).to have_text("No declaration has been added to the form.")
      end
    end

    context "when the form has no payment URL" do
      let(:form) { build_form(payment_url: nil) }

      it "does not render a payment URL text input" do
        expect(rendered).not_to have_field("Payment URL", type: "text")
      end
    end

    context "when the form has no support URL" do
      let(:form) { build_form(support_url: nil) }

      it "does not render a support URL text input" do
        expect(rendered).not_to have_field("Support URL", type: "text")
        expect(rendered).not_to have_field("Support URL text", type: "text")
      end
    end

    context "when the form has no support phone" do
      let(:form) { build_form(support_phone: nil) }

      it "does not render a support phone text area" do
        expect(rendered).not_to have_field("Support phone", type: "textarea")
      end
    end

    context "when the form has no support email" do
      let(:form) { build_form(support_email: nil) }

      it "does not render a support email text input" do
        expect(rendered).not_to have_field("Support email", type: "text")
      end
    end

    context "when the form has no support information" do
      let(:form) { build_form(support_email: nil, support_phone: nil, support_url: nil, support_url_text: nil) }

      it "does not render support information" do
        expect(rendered).not_to have_text("Contact details for support", exact: true)
      end

      it "renders message for no support information" do
        expect(rendered).to have_text("No contact details for support have been added to the form yet.")
      end
    end

    context "when the form has no what happens next information" do
      let(:form) { build_form(what_happens_next_markdown: nil) }

      it "does not render what happens next information" do
        expect(rendered).not_to have_field("What happens next", type: "textarea")
      end

      it "renders message for no what happens next information" do
        expect(rendered).to have_text("No information about what happens next has been added to the form yet.")
      end
    end

    context "when the form has no privacy information" do
      let(:form) { build_form(privacy_policy_url: nil) }

      it "does not render privacy information field" do
        expect(rendered).not_to have_field("Privacy policy URL", type: "text")
      end

      it "renders message for no privacy information" do
        expect(rendered).to have_text("No privacy information has been added to the form yet.")
      end
    end

    context "when the form does not have any pages" do
      let(:form) { build_form(pages_count: 0) }
      let(:welsh_translation_input) { build_welsh_translation_input }

      before { render_welsh_translation_form }

      it "does not render any page translation content" do
        expect(rendered).not_to have_field(id: /forms_welsh_page_translation_input_.*_page_translations_question_text_cy/, type: "text")
      end

      it "renders message for no pages" do
        expect(rendered).to have_text("No questions have been added to the form yet.")
      end
    end

    context "when the form has pages" do
      it "has a field for each page's Welsh question text" do
        expect(rendered).to have_field("Enter Welsh question text for question #{page.position}", type: "text", id: "forms_welsh_page_translation_input_#{page.id}_page_translations_question_text_cy")
        expect(rendered).to have_field("Enter Welsh question text for question #{another_page.position}", type: "text", id: "forms_welsh_page_translation_input_#{another_page.id}_page_translations_question_text_cy")
      end

      context "when a page has hint text" do
        before do
          hash = form.draft_content_service.content_hash
          hash["steps"][0]["hint_text"] = { "en" => "Choose 'Yes' if you already have a valid licence." }
          hash["steps"][1]["hint_text"] = { "en" => "" }
          FormDocumentOperationsService.new(form).save_draft_content!(hash)
          form.reload
          render_welsh_translation_form
        end

        it "shows the English text and Welsh field for pages with English hint text" do
          expect(rendered).to have_css("td", text: page.hint_text)
          expect(rendered).to have_field("Enter Welsh hint text for question #{page.position}", type: "textarea", id: "forms_welsh_page_translation_input_#{page.id}_page_translations_hint_text_cy")
        end

        it "does not show the Welsh field for pages without English hint text" do
          expect(rendered).not_to have_field("Enter Welsh hint text for question #{another_page.position}")
        end
      end

      context "when a page has a page heading and guidance markdown" do
        before do
          hash = form.draft_content_service.content_hash
          hash["steps"][0]["page_heading"] = { "en" => "" }
          hash["steps"][0]["guidance_markdown"] = { "en" => "" }
          hash["steps"][1]["page_heading"] = { "en" => "Licencing" }
          hash["steps"][1]["guidance_markdown"] = { "en" => "This part of the form concerns licencing." }
          FormDocumentOperationsService.new(form).save_draft_content!(hash)
          form.reload
          render_welsh_translation_form
        end

        it "shows the English text and Welsh fields for pages with English page heading and guidance markdown" do
          expect(rendered).to have_css("td", text: another_page.page_heading)
          expect(rendered).to have_field("Enter Welsh page heading for question #{another_page.position}", id: "forms_welsh_page_translation_input_#{another_page.id}_page_translations_page_heading_cy")
          expect(rendered).to have_css("td", text: another_page.guidance_markdown)
          expect(rendered).to have_field("Enter Welsh guidance text for question #{another_page.position}", id: "forms_welsh_page_translation_input_#{another_page.id}_page_translations_guidance_markdown_cy")
        end

        it "does not show the Welsh field for pages without English page heading and guidance markdown" do
          expect(rendered).not_to have_field("Enter Welsh page heading for question #{page.position}")
          expect(rendered).not_to have_field("Enter Welsh guidance text for question #{page.position}", type: "textarea")
        end
      end

      context "when a page has a selection question" do
        before do
          hash = form.draft_content_service.content_hash
          hash["steps"][0]["answer_type"] = "selection"
          hash["steps"][0]["data"] = {
            "answer_settings" => {
              "only_one_option" => "true",
              "selection_options" => [{ "name" => "Option 1", "value" => "Option 1" }, { "name" => "Option 2", "value" => "Option 2" }],
            },
          }
          FormDocumentOperationsService.new(form).save_draft_content!(hash)
          form.reload
          render_welsh_translation_form
        end

        it "shows the selection heading" do
          expect(rendered).to have_css("caption", text: t("forms.welsh_translation.new.section_headings.selection_options", question_number: page.position))
        end

        it "shows the English text and Welsh field for pages with English selection options" do
          selection_page = form.reload.pages.first
          expect(rendered).to have_css("td", text: selection_page.answer_settings.selection_options.first.name)
          expect(rendered).to have_field("Enter Welsh option 1")

          expect(rendered).to have_css("td", text: selection_page.answer_settings.selection_options.second.name)
          expect(rendered).to have_field("Enter Welsh option 2")
        end
      end

      context "when a page has a selection question with none of the above" do
        before do
          hash = form.draft_content_service.content_hash
          hash["steps"] = [hash["steps"].first]
          hash["steps"][0]["answer_type"] = "selection"
          hash["steps"][0]["data"] = {
            "is_optional" => true,
            "answer_settings" => {
              "only_one_option" => "true",
              "selection_options" => [{ "name" => "Option 1", "value" => "Option 1" }, { "name" => "Option 2", "value" => "Option 2" }],
              "none_of_the_above_question" => {
                "question_text" => { "en" => "None of the above question?" },
                "is_optional" => "true",
              },
            },
          }
          FormDocumentOperationsService.new(form).save_draft_content!(hash)
          form.reload
          render_welsh_translation_form
        end

        let(:another_welsh_page_translation_input) { nil }

        it "has row for the none of the above question text" do
          expect(rendered).to have_css("th", text: t("forms.welsh_translation.new.none_of_the_above_question"))
        end

        it "shows the English text and Welsh field for none of the above question" do
          selection_page = form.reload.pages.first
          expect(rendered).to have_css("td", text: selection_page.answer_settings.none_of_the_above_question.question_text)
          expect(rendered).to have_field("Enter Welsh question or label if ‘None of the above’ is selected")
        end
      end

      context "when at least one page has routing conditions" do
        context "when the condition has an exit page" do
          let!(:condition) { create(:condition, :with_exit_page, form:, routing_page_id: form.pages.first.id, check_page_id: form.pages.first.id) }
          let(:welsh_condition_translation_input) { Forms::WelshConditionTranslationInput.new(condition:).assign_condition_values }

          before do
            form.reload
            render_welsh_translation_form
          end

          it "shows a caption with the page the condition applies to" do
            expect(rendered).to have_css("caption", text: t("forms.welsh_translation.new.condition.heading", question_number: condition.routing_page.position))
          end

          it "shows the English text and Welsh field for each condition's exit page fields" do
            expect(rendered).to have_css("td", text: condition.exit_page_heading)
            expect(rendered).to have_field("Enter Welsh exit page heading for question #{condition.routing_page.position}", type: "text", id: welsh_condition_translation_input.form_field_id(:exit_page_heading_cy))
            expect(rendered).to have_css("td", text: condition.exit_page_markdown)
            expect(rendered).to have_field("Enter Welsh exit page content for question #{condition.routing_page.position}", type: "textarea", id: welsh_condition_translation_input.form_field_id(:exit_page_markdown_cy))
          end
        end
      end
    end
  end

  context "when the form has validation errors" do
    let(:mark_complete) { nil }

    before do
      welsh_translation_input.validate

      assign(:welsh_translation_input, welsh_translation_input)
      render
    end

    it "displays an error summary box" do
      expect(rendered).to have_css(".govuk-error-summary")
      expect(rendered).to have_css("h2.govuk-error-summary__title", text: "There is a problem")
    end

    it "links the error summary to the invalid field" do
      error_message = I18n.t("activemodel.errors.models.forms/welsh_translation_input.attributes.mark_complete.blank")
      expect(rendered).to have_link(error_message, href: "#forms-welsh-translation-input-mark-complete-field-error")
    end

    it "adds an inline error message to the invalid field" do
      error_message = "Error: #{I18n.t('activemodel.errors.models.forms/welsh_translation_input.attributes.mark_complete.blank')}"
      expect(rendered).to have_css(".govuk-error-message", text: error_message)
    end
  end

  context "when a page translation has validation errors" do
    before do
      welsh_page_translation_input.question_text_cy = nil
      welsh_translation_input.validate(mark_complete ? :mark_complete : nil)

      assign(:welsh_translation_input, welsh_translation_input)
      render
    end

    it "displays an error summary box" do
      expect(rendered).to have_css(".govuk-error-summary")
      expect(rendered).to have_css("h2.govuk-error-summary__title", text: "There is a problem")
    end

    it "links the error summary to the invalid field" do
      error_message = I18n.t("activemodel.errors.models.forms/welsh_page_translation_input.attributes.question_text_cy.blank", question_number: page.position)
      expect(rendered).to have_link(error_message, href: "#forms_welsh_page_translation_input_#{page.id}_page_translations_question_text_cy")
    end

    it "adds an inline error message to the invalid field" do
      error_message = "Error: #{I18n.t('activemodel.errors.models.forms/welsh_page_translation_input.attributes.question_text_cy.blank', question_number: page.position)}"
      expect(rendered).to have_css(".govuk-error-message", text: error_message)
    end
  end

  context "when a condition translation has validation errors" do
    let(:form) do
      build_form(
        payment_url: "https://www.gov.uk/payments/your-payment-link",
        payment_url_cy: "https://www.gov.uk/payments/your-payment-link",
      )
    end
    let!(:exit_page_condition) { create(:condition, :with_exit_page, form:, routing_page_id: form.pages.first.id, check_page_id: form.pages.first.id, answer_value: "Yes") }
    let(:condition) { exit_page_condition }

    before do
      form.reload
      input = build_welsh_translation_input.tap { |translation_input| translation_input.mark_complete = mark_complete }
      condition_translation = input.page_translations.flat_map(&:condition_translations).first
      condition_translation.exit_page_heading_cy = nil
      input.validate(mark_complete ? :mark_complete : nil)
      assign(:welsh_translation_input, input)
      render
    end

    it "displays an error summary box" do
      expect(rendered).to have_css(".govuk-error-summary")
      expect(rendered).to have_css("h2.govuk-error-summary__title", text: "There is a problem")
    end

    it "links the error summary to the invalid field" do
      error_message = I18n.t("activemodel.errors.models.forms/welsh_condition_translation_input.attributes.exit_page_heading_cy.blank", question_number: condition.routing_page.position)
      expect(rendered).to have_link(error_message, href: "#forms_welsh_condition_translation_input_#{condition.id}_condition_translations_exit_page_heading_cy")
    end

    it "adds an inline error message to the invalid field" do
      error_message = "Error: #{I18n.t('activemodel.errors.models.forms/welsh_condition_translation_input.attributes.exit_page_heading_cy.blank', question_number: condition.routing_page.position)}"
      expect(rendered).to have_css(".govuk-error-message", text: error_message)
    end
  end
end
