require "rails_helper"

RSpec.describe "WelshCsvService" do
  describe "#as_csv" do
    let(:form) { create(:form) }

    it "contains the header row" do
      expect(csv_rows(form)[0]).to contain_exactly(
        "",
        "English content",
        "Welsh content",
      )
    end

    it "contains the form name" do
      expect(csv_rows(form)).to include([
        "Form name",
        form.name,
        form.name_cy,
      ])
    end

    context "when the form has a declaration" do
      let(:form) do
        f = create(:form, declaration_markdown: "Declaration text")
        f.declaration_markdown_cy = "Welsh Declaration text"
        f.save_question_changes!
        f.reload
      end

      it "contains the declaration" do
        expect(csv_rows(form)).to include([
          "Declaration",
          "Declaration text",
          "Welsh Declaration text",
        ])
      end
    end

    context "when the form has a what happens next" do
      let(:form) do
        f = create(:form, what_happens_next_markdown: "What happens next text")
        f.what_happens_next_markdown_cy = "Welsh What happens next text"
        f.save_question_changes!
        f.reload
      end

      it "contains the what happens next" do
        expect(csv_rows(form)).to include([
          "Information about what happens next",
          "What happens next text",
          "Welsh What happens next text",
        ])
      end
    end

    context "when the form has a payment URL" do
      let(:form) do
        f = create(:form, payment_url: "https://www.gov.uk/payment")
        f.payment_url_cy = "https://www.gov.uk/payment_cy"
        f.save_question_changes!
        f.reload
      end

      it "contains the payment URL" do
        expect(csv_rows(form)).to include([
          "GOV⁠.⁠UK Pay payment link",
          "https://www.gov.uk/payment",
          "https://www.gov.uk/payment_cy",
        ])
      end
    end

    context "when the form has support information" do
      context "when the form has an email address" do
        let(:form) do
          f = create(:form, support_email: "support@example.gov.uk")
          f.support_email_cy = "support@example.gov.uk"
          f.save_question_changes!
          f.reload
        end

        it "contains the support email" do
          expect(csv_rows(form)).to include([
            "Contact details for support - email address",
            "support@example.gov.uk",
            "support@example.gov.uk",
          ])
        end
      end

      context "when the form has a phone number" do
        let(:form) do
          f = create(:form, support_phone: "English support phone")
          f.support_phone_cy = "Welsh support phone"
          f.save_question_changes!
          f.reload
        end

        it "contains the support phone" do
          expect(csv_rows(form)).to include([
            "Contact details for support - phone number and opening times",
            "English support phone",
            "Welsh support phone",
          ])
        end
      end

      context "when the form has a URL" do
        let(:form) do
          f = create(:form,
                     support_url: "https://www.gov.uk/support",
                     support_url_text: "Text to describe the contact link")
          f.support_url_cy = "https://www.gov.uk/support_cy"
          f.support_url_text_cy = "Welsh Text to describe the contact link"
          f.save_question_changes!
          f.reload
        end

        it "contains the support URL" do
          expect(csv_rows(form)).to include([
            "Contact details for support - online contact link",
            "https://www.gov.uk/support",
            "https://www.gov.uk/support_cy",
          ])
        end

        it "contains the support URL text" do
          expect(csv_rows(form)).to include([
            "Contact details for support - online contact link text",
            "Text to describe the contact link",
            "Welsh Text to describe the contact link",
          ])
        end
      end
    end

    context "when the form has questions" do
      let(:form) { create(:form, :with_pages) }

      it "contains a row for each question" do
        expect(csv_rows(form).length).to eq form.pages.length + 3
      end
    end

    context "and the form has a page" do
      let(:form) do
        create(:form, pages_count: 1).tap do |f|
          f.pages.first.tap do |page|
            page.question_text = "Question text"
            page.question_text_cy = "Welsh question text"
            page.save_and_update_form
          end
          f.reload
        end
      end

      it "contains the question text" do
        expect(csv_rows(form)).to include([
          "Question 1 - question text",
          "Question text",
          "Welsh question text",
        ])
      end
    end

    context "and the form has a page with a hint" do
      let(:form) do
        create(:form, pages_count: 1).tap do |f|
          f.pages.first.tap do |page|
            page.hint_text = "Hint text"
            page.hint_text_cy = "Welsh hint text"
            page.save_and_update_form
          end
          f.reload
        end
      end

      it "contains the hint text" do
        expect(csv_rows(form)).to include([
          "Question 1 - hint text",
          "Hint text",
          "Welsh hint text",
        ])
      end
    end

    context "and the form has a page with options" do
      let(:form) do
        create(:form, pages_count: 1).tap do |f|
          f.pages.first.tap do |page|
            page.question_text = "Question text"
            page.answer_type = "selection"
            page.answer_settings = {
              "only_one_option" => "true",
              "selection_options" => [{ "name" => "Yes", "value" => "Yes" }, { "name" => "No", "value" => "No" }],
            }
            page.answer_settings_cy = {
              "only_one_option" => "true",
              "selection_options" => [{ "name" => "Ydy", "value" => "Yes" }, { "name" => "Nac ydy", "value" => "No" }],
            }
            page.save_and_update_form
          end
          f.reload
        end
      end

      it "contains the options" do
        expect(csv_rows(form)).to include([
          "Question 1 - option 1",
          "Yes",
          "Ydy",
        ], [
          "Question 1 - option 2",
          "No",
          "Nac ydy",
        ])
      end
    end

    context "and the form has a page with guidance" do
      let(:form) do
        create(:form, pages_count: 1).tap do |f|
          f.pages.first.tap do |page|
            page.guidance_markdown = "Markdown"
            page.guidance_markdown_cy = "Welsh markdown"
            page.page_heading = "Page heading"
            page.page_heading_cy = "Welsh page heading"
            page.save_and_update_form
          end
          f.reload
        end
      end

      it "contains the guidance" do
        expect(csv_rows(form)).to include([
          "Question 1 - guidance text",
          "Markdown",
          "Welsh markdown",
        ], [
          "Question 1 - page heading",
          "Page heading",
          "Welsh page heading",
        ])
      end
    end

    context "when the page has a none of the above question" do
      let(:form) do
        create(:form, pages_count: 0).tap do |f|
          create(:page,
                 form: f,
                 :selection_with_none_of_the_above_question,
                 none_of_the_above_question_text: "None of the above question?")
          f.reload.pages.first.tap do |page|
            page.answer_settings_cy = {
              "only_one_option" => "true",
              "selection_options" => page.answer_settings["selection_options"],
              "none_of_the_above_question" => {
                "question_text" => "Welsh None of the above question?",
              },
            }
            page.save_and_update_form
          end
          f.reload
        end
      end

      it "contains the none of the above question" do
        expect(csv_rows(form)).to include([
          "Question 1 - question or label if ‘None of the above’ is selected",
          "None of the above question?",
          "Welsh None of the above question?",
        ])
      end
    end

    context "when the page has an exit condition" do
      let(:form) do
        f = create(:form, pages_count: 1)
        page = f.pages.first
        create(:condition,
               form: f,
               routing_page: page,
               :with_exit_page,
               exit_page_heading: "Exit page heading",
               exit_page_markdown: "Exit page markdown",
               exit_page_heading_cy: "Welsh exit page heading",
               exit_page_markdown_cy: "Welsh exit page markdown")
        f.reload
      end

      it "contains the exit page heading" do
        expect(csv_rows(form)).to include([
          "Question 1 - exit page heading",
          "Exit page heading",
          "Welsh exit page heading",
        ])
      end
    end

    context "with a complete example" do
      let(:form) do
        f = create(:form,
                   pages_count: 0,
                   name: "A form",
                   what_happens_next_markdown: "English what happens next",
                   privacy_policy_url: "https://www.gov.uk/privacy",
                   payment_url: "https://www.gov.uk/payment",
                   support_email: "support@example.gov.uk",
                   support_phone: "English support phone",
                   support_url: "https://www.gov.uk/support",
                   support_url_text: "Support URL text",
                   declaration_markdown: "Declaration text")
        f.name_cy = "Welsh A form"
        f.what_happens_next_markdown_cy = "Welsh what happens next"
        f.payment_url_cy = "https://www.gov.uk/payment_cy"
        f.support_email_cy = "support@example.gov.uk"
        f.support_phone_cy = "Welsh support phone"
        f.support_url_cy = "https://www.gov.uk/support_cy"
        f.support_url_text_cy = "Welsh Support URL text"
        f.save_question_changes!

        page = create(:page,
                      form: f,
                      :selection_with_none_of_the_above_question,
                      question_text: "None of the above question?",
                      none_of_the_above_question_text: "None of the above question?")
        page.question_text_cy = "Welsh None of the above question?"
        page.answer_settings_cy = {
          "only_one_option" => "true",
          "selection_options" => page.answer_settings["selection_options"],
          "none_of_the_above_question" => { "question_text" => "Welsh None of the above question?" },
        }
        page.save_and_update_form

        create(:condition,
               form: f,
               routing_page: page,
               :with_exit_page,
               exit_page_heading: "Exit page heading",
               exit_page_markdown: "Exit page markdown",
               exit_page_heading_cy: "Welsh exit page heading",
               exit_page_markdown_cy: "Welsh exit page markdown")

        another_page = create(:page,
                              form: f,
                              question_text: "What?",
                              page_heading: "Page heading",
                              guidance_markdown: "This is the guidance.")
        another_page.question_text_cy = "Welsh What?"
        another_page.page_heading_cy = "Welsh Page heading"
        another_page.guidance_markdown_cy = "Welsh This is the guidance."
        another_page.save_and_update_form

        f.reload
      end

      it "returns a CSV with a header row and the expected rows" do
        csv = csv_rows(form)

        expected_csv = [["", "English content", "Welsh content"],
                        ["Form name", "A form", "Welsh A form"],
                        ["Question 1 - question text", "None of the above question?", "Welsh None of the above question?"],
                        ["Question 1 - option 1", "Option 1", "Option 1"],
                        ["Question 1 - option 2", "Option 2", "Option 2"],
                        ["Question 1 - question or label if ‘None of the above’ is selected", "None of the above question?", "Welsh None of the above question?"],
                        ["Question 1 - exit page heading", "Exit page heading", "Welsh exit page heading"],
                        ["Question 1 - exit page content", "Exit page markdown", "Welsh exit page markdown"],
                        ["Question 2 - question text", "What?", "Welsh What?"],
                        ["Question 2 - page heading", "Page heading", "Welsh Page heading"],
                        ["Question 2 - guidance text", "This is the guidance.", "Welsh This is the guidance."],
                        ["Declaration", "Declaration text", ""],
                        ["Information about what happens next", "English what happens next", "Welsh what happens next"],
                        ["GOV⁠.⁠UK Pay payment link", "https://www.gov.uk/payment", "https://www.gov.uk/payment_cy"],
                        ["Link to privacy information for this form", "https://www.gov.uk/privacy", ""],
                        ["Contact details for support - email address", "support@example.gov.uk", "support@example.gov.uk"],
                        ["Contact details for support - phone number and opening times", "English support phone", "Welsh support phone"],
                        ["Contact details for support - online contact link", "https://www.gov.uk/support", "https://www.gov.uk/support_cy"],
                        ["Contact details for support - online contact link text", "Support URL text", "Welsh Support URL text"]]
        expect(csv).to match_array(expected_csv)
      end
    end
  end

  describe "#filename" do
    let(:form) { create(:form, name: "My form: \"full of odd.\\..\. characters\"") }

    it "returns a filename with a safe form name" do
      expect(WelshCsvService.new(form).filename).to eq("my_form_full_of_odd_characters.csv")
    end

    context "when the form name is too long" do
      let(:form) { create(:form, name: "a" * 120) }

      it "returns a filename with a safe form name" do
        expect(WelshCsvService.new(form).filename.length).to eq(80)
      end
    end
  end
end

def csv_rows(form)
  csv = WelshCsvService.new(form).as_csv
  CSV.parse(csv)
end
