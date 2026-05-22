# frozen_string_literal: true

class Reports::FormDocumentsService
  class << self
    def form_documents(tag:)
      scope = FormDocument.joins(form: { group_form: { group: :organisation } })
        .where.not(organisation: { internal: true })
        .select(
          "form_documents.*",
          "organisation.name AS organisation_name",
          "organisation.id AS organisation_id",
          "groups.external_id AS group_external_id",
          "groups.name AS group_name",
          "forms.welsh_completed AS welsh_completed",
        )

      scope = case tag.to_s
              when "draft"
                scope.joins(:form).where("form_documents.id = forms.draft_form_document_id")
              when "live"
                scope.joins(:form).where("form_documents.id = forms.live_form_document_id").where(forms: { archived: false })
              when "live-or-archived"
                scope.joins(:form).where("form_documents.id = forms.live_form_document_id")
              else
                scope.none
              end

      scope.find_each(batch_size: 100).lazy.map do |doc|
        json = doc.as_json
        json["content"] = FormDocument::LocaleProjection.project(doc.content, language: "en")
        json["language"] = "en"
        json
      end
    end

    def has_routes?(form_document)
      form_document_content(form_document)["steps"].any? { |step| step["routing_conditions"].present? }
    end

    def has_secondary_skip_routes?(form_document)
      secondary_skip_conditions(form_document).any?
    end

    def count_secondary_skip_routes(form_document)
      secondary_skip_conditions(form_document).count
    end

    def step_has_secondary_skip_route?(form_document, step)
      secondary_skip_conditions(form_document).any? do |condition|
        condition["check_page_id"] == step["id"]
      end
    end

    def has_add_another_answer?(form_document)
      form_document_content(form_document)["steps"].any? { |step| step.dig("data", "is_repeatable") }
    end

    def has_payments?(form_document)
      payment_url = form_document_content(form_document)["payment_url"]
      payment_url.present?
    end

    def has_csv_submission_email_attachments(form_document)
      content = form_document_content(form_document)
      content["submission_type"] == "email" && content["submission_format"].include?("csv")
    end

    def has_json_submission_email_attachments(form_document)
      content = form_document_content(form_document)
      content["submission_type"] == "email" && content["submission_format"].include?("json")
    end

    def has_daily_submission_csv(form_document)
      form_document_content(form_document)["send_daily_submission_batch"]
    end

    def has_weekly_submission_csv(form_document)
      form_document_content(form_document)["send_weekly_submission_batch"]
    end

    def has_s3_submissions(form_document)
      form_document_content(form_document)["submission_type"] == "s3"
    end

    def has_exit_pages?(form_document)
      form_document_content(form_document)["steps"].any? do |step|
        step["routing_conditions"].any? do |condition|
          markdown = condition["exit_page_markdown"]
          markdown.is_a?(Hash) ? markdown.values.any?(&:present?) : markdown.present?
        end
      end
    end

    def is_copy?(form_document)
      form_document_content(form_document)["copied_from_id"].present?
    end

    def has_welsh_translation(form_document)
      case form_document
      when Form
        form_document.welsh_completed?
      when Hash
        form_document["welsh_completed"].present?
      else
        form_document.form.welsh_completed?
      end
    end

  private

    def form_document_content(form_document)
      case form_document
      when Hash
        form_document.fetch("content")
      else
        form_document.content
      end
    end

    def secondary_skip_conditions(form_document)
      form_document_content(form_document)["steps"].lazy.flat_map do |step|
        (step["routing_conditions"]&.lazy || []).reject do |condition|
          condition["check_page_id"] == condition["routing_page_id"]
        end
      end
    end
  end
end
