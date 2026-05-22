# frozen_string_literal: true

class DocumentOnlyFormsMigration < ActiveRecord::Migration[8.1]
  class MigrationForm < ActiveRecord::Base
    self.table_name = "forms"
  end

  class MigrationFormDocument < ActiveRecord::Base
    self.table_name = "form_documents"
  end

  class MigrationPage < ActiveRecord::Base
    self.table_name = "pages"
    has_many :routing_conditions, class_name: "MigrationCondition", foreign_key: "routing_page_id"
  end

  class MigrationCondition < ActiveRecord::Base
    self.table_name = "conditions"
    belongs_to :routing_page, class_name: "MigrationPage"
    belongs_to :check_page, class_name: "MigrationPage", optional: true
    belongs_to :goto_page, class_name: "MigrationPage", optional: true
  end

  class MigrationFormTranslation < ActiveRecord::Base
    self.table_name = "form_translations"
  end

  class MigrationPageTranslation < ActiveRecord::Base
    self.table_name = "page_translations"
  end

  class MigrationConditionTranslation < ActiveRecord::Base
    self.table_name = "condition_translations"
  end

  def up
    add_reference :forms, :draft_form_document, foreign_key: { to_table: :form_documents }, null: true
    add_reference :forms, :live_form_document, foreign_key: { to_table: :form_documents }, null: true
    add_column :forms, :archived, :boolean, default: false, null: false
    add_column :form_documents, :published_at, :datetime
    add_reference :form_documents, :supersedes, foreign_key: { to_table: :form_documents }, null: true

    remove_index :form_documents, name: "index_form_documents_on_form_id_tag_and_language", if_exists: true
    change_column_null :form_documents, :tag, true
    change_column_null :form_documents, :language, true

    migrate_to_document_only

    remove_column :forms, :state, :string
    remove_column :forms, :available_languages, :text, array: true, default: ["en"]
    remove_column :form_documents, :tag, :text
    remove_column :form_documents, :language, :string

    %i[
      name form_slug submission_type submission_format submission_email
      declaration_text declaration_markdown privacy_policy_url
      support_email support_phone support_url support_url_text
      payment_url what_happens_next_markdown
      s3_bucket_name s3_bucket_region s3_bucket_aws_account_id
      send_daily_submission_batch send_weekly_submission_batch send_copy_of_answers
    ].each do |column|
      remove_column :forms, column if column_exists?(:forms, column)
    end

    drop_table :condition_translations, if_exists: true
    drop_table :page_translations, if_exists: true
    drop_table :form_translations, if_exists: true
    drop_table :conditions, if_exists: true
    drop_table :pages, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

private

  def migrate_to_document_only
    MigrationForm.find_each do |form|
      migrate_form(form)
    end
  end

  def migrate_form(form)
    state = form.read_attribute(:state)
    archived = state.in?(%w[archived archived_with_draft])

    draft_doc = merge_tag_documents(form.id, "draft")
    live_doc = merge_tag_documents(form.id, "live")
    archived_doc = merge_tag_documents(form.id, "archived")

    if draft_doc.nil? && live_doc.nil? && archived_doc.nil? && MigrationPage.exists?(form_id: form.id)
      draft_doc = MigrationFormDocument.create!(
        form_id: form.id,
        content: build_content_from_relational(form),
      )
    end

    live_pointer = archived ? archived_doc : live_doc
    live_pointer ||= archived_doc

    draft_pointer_id = if state.in?(%w[draft live_with_draft archived_with_draft])
                         draft_doc&.id
                       end

    form.update_columns(
      draft_form_document_id: draft_pointer_id,
      live_form_document_id: live_pointer&.id,
      archived: archived,
    )

    keep_ids = [draft_doc, live_doc, archived_doc].compact.map(&:id)
    MigrationFormDocument.where(form_id: form.id).where.not(id: keep_ids).delete_all
  end

  def merge_tag_documents(form_id, tag)
    en = MigrationFormDocument.find_by(form_id:, tag:, language: "en")
    cy = MigrationFormDocument.find_by(form_id:, tag:, language: "cy")
    return nil if en.blank? && cy.blank?

    en_content = en&.content || {}
    cy_content = cy&.content || {}
    content = DocumentOnlyForms::ContentMerger.merge_documents(
      en_doc: OpenStruct.new(content: en_content),
      cy_doc: cy.present? ? OpenStruct.new(content: cy_content) : nil,
    )
    content["form_id"] = form_id.to_s
    MigrationFormDocument.create!(form_id:, content:)
  end

  def build_content_from_relational(form)
    en_trans = MigrationFormTranslation.find_by(form_id: form.id, locale: "en")
    cy_trans = MigrationFormTranslation.find_by(form_id: form.id, locale: "cy")
    pages = MigrationPage.where(form_id: form.id).order(:position)

    content = {
      "form_id" => form.id.to_s,
      "name" => merge_locale_field(en_trans&.name, cy_trans&.name),
      "form_slug" => form.read_attribute(:form_slug),
      "available_languages" => form.read_attribute(:available_languages) || %w[en],
      "submission_type" => form.read_attribute(:submission_type),
      "submission_format" => form.read_attribute(:submission_format) || [],
      "submission_email" => form.read_attribute(:submission_email),
      "declaration_text" => merge_locale_field(en_trans&.declaration_text, cy_trans&.declaration_text),
      "declaration_markdown" => merge_locale_field(en_trans&.declaration_markdown, cy_trans&.declaration_markdown),
      "privacy_policy_url" => merge_locale_field(en_trans&.privacy_policy_url, cy_trans&.privacy_policy_url),
      "support_email" => merge_locale_field(en_trans&.support_email, cy_trans&.support_email),
      "support_phone" => merge_locale_field(en_trans&.support_phone, cy_trans&.support_phone),
      "support_url" => merge_locale_field(en_trans&.support_url, cy_trans&.support_url),
      "support_url_text" => merge_locale_field(en_trans&.support_url_text, cy_trans&.support_url_text),
      "payment_url" => merge_locale_field(en_trans&.payment_url, cy_trans&.payment_url),
      "what_happens_next_markdown" => merge_locale_field(en_trans&.what_happens_next_markdown, cy_trans&.what_happens_next_markdown),
      "s3_bucket_name" => form.read_attribute(:s3_bucket_name),
      "s3_bucket_region" => form.read_attribute(:s3_bucket_region),
      "s3_bucket_aws_account_id" => form.read_attribute(:s3_bucket_aws_account_id),
      "send_daily_submission_batch" => form.read_attribute(:send_daily_submission_batch),
      "send_weekly_submission_batch" => form.read_attribute(:send_weekly_submission_batch),
      "send_copy_of_answers" => form.read_attribute(:send_copy_of_answers),
      "steps" => pages.map.with_index { |page, index| build_step(page, pages[index + 1]) },
    }
    content["start_page"] = pages.first&.external_id
    content
  end

  def build_step(page, next_page)
    en_pt = MigrationPageTranslation.find_by(page_id: page.id, locale: "en")
    cy_pt = MigrationPageTranslation.find_by(page_id: page.id, locale: "cy")
    {
      "id" => page.external_id,
      "type" => "question",
      "position" => page.position,
      "next_step_id" => next_page&.external_id,
      "question_text" => merge_locale_field(en_pt&.question_text, cy_pt&.question_text),
      "hint_text" => merge_locale_field(en_pt&.hint_text, cy_pt&.hint_text),
      "page_heading" => merge_locale_field(en_pt&.page_heading, cy_pt&.page_heading),
      "guidance_markdown" => merge_locale_field(en_pt&.guidance_markdown, cy_pt&.guidance_markdown),
      "answer_type" => page.answer_type,
      "data" => {
        "is_optional" => page.is_optional,
        "is_repeatable" => page.is_repeatable,
        "answer_settings" => en_pt&.answer_settings,
      }.compact,
      "routing_conditions" => MigrationCondition.where(routing_page_id: page.id).map { |c| build_condition(c) },
    }
  end

  def build_condition(condition)
    en_ct = MigrationConditionTranslation.find_by(condition_id: condition.id, locale: "en")
    cy_ct = MigrationConditionTranslation.find_by(condition_id: condition.id, locale: "cy")
    {
      "id" => condition.id,
      "answer_value" => condition.answer_value,
      "skip_to_end" => condition.skip_to_end,
      "routing_page_id" => condition.routing_page&.external_id,
      "check_page_id" => MigrationPage.find_by(id: condition.check_page_id)&.external_id,
      "goto_page_id" => MigrationPage.find_by(id: condition.goto_page_id)&.external_id,
      "exit_page_heading" => merge_locale_field(en_ct&.exit_page_heading, cy_ct&.exit_page_heading),
      "exit_page_markdown" => merge_locale_field(en_ct&.exit_page_markdown, cy_ct&.exit_page_markdown),
    }
  end

  def merge_locale_field(en_val, cy_val)
    result = {}
    result["en"] = en_val if en_val.present?
    result["cy"] = cy_val if cy_val.present?
    result
  end
end
