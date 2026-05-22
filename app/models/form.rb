# frozen_string_literal: true

class Form < ApplicationRecord
  SUPPORTED_LANGUAGES = %w[en cy].freeze

  belongs_to :draft_form_document, class_name: "FormDocument", optional: true
  belongs_to :live_form_document, class_name: "FormDocument", optional: true
  has_one :form_submission_email, dependent: :destroy
  has_one :group_form, dependent: :destroy
  has_many :form_documents, dependent: :destroy

  after_create :set_external_id
  after_create :create_initial_draft_document

  attr_accessor :task_status_service

  def draft_content_service
    FormDraftContentService.new(self)
  end

  def save_question_changes!
    draft_content_service.save_question_changes!
  end

  def save_draft!
    FormDocumentOperationsService.new(self).save_draft!
  end

  attr_accessor :previous_lifecycle_status

  def state
    lifecycle_status.to_s
  end

  def state_previously_changed?
    previous_lifecycle_status.present? && previous_lifecycle_status != lifecycle_status
  end

  def state_previously_was
    previous_lifecycle_status&.to_s
  end

  def lifecycle_status
    return :archived_with_draft if self[:archived] && draft_form_document_id.present?
    return :archived if self[:archived]
    return :draft if live_form_document_id.nil? && draft_form_document_id.present?
    return :live_with_draft if live_form_document_id.present? && draft_form_document_id.present?
    return :live if live_form_document_id.present?

    :draft
  end

  def draft?
    lifecycle_status == :draft
  end

  def live?
    lifecycle_status == :live
  end

  def live_with_draft?
    lifecycle_status == :live_with_draft
  end

  def archived?
    lifecycle_status == :archived || lifecycle_status == :archived_with_draft
  end

  def archived_with_draft?
    lifecycle_status == :archived_with_draft
  end

  def has_draft_version
    draft? || live_with_draft? || archived_with_draft?
  end

  def has_live_version
    live? || live_with_draft?
  end

  alias_method :is_live?, :has_live_version

  def has_been_archived
    lifecycle_status == :archived || lifecycle_status == :archived_with_draft
  end

  alias_method :is_archived?, :has_been_archived

  def pages
    list = draft_content_service.steps_for_list
    list.define_singleton_method(:find_by!) do |**conditions|
      page = list.find { |candidate| conditions.all? { |attr, value| candidate.public_send(attr) == value } }
      raise ActiveRecord::RecordNotFound unless page

      page
    end
    list.define_singleton_method(:reorder) { |*_args| self }
    list.define_singleton_method(:in_order_of) do |field, values|
      field = field.to_s
      normalized_values = values.map(&:to_s)
      sort_by do |page|
        value = page.public_send(field == "id" ? :id : field).to_s
        normalized_values.index(value) || normalized_values.length
      end
    end
    list
  end

  def pages=(page_list)
    if page_list.blank?
      hash = draft_content_service.content_hash
      hash["steps"] = []
      hash.delete("start_page")
      FormDocumentOperationsService.new(self).save_draft_content!(hash)
      return
    end

    page_list.each do |page|
      attrs = if page.is_a?(FormStep)
                page.step_data
              else
                {
                  id: page.try(:external_id) || page.try(:id),
                  question_text: page.try(:question_text),
                  answer_type: page.try(:answer_type),
                  position: page.try(:position),
                }
              end
      draft_content_service.add_step!(attrs) unless attrs["id"] && draft_content_service.find_step(attrs["id"])
    end
  end

  def conditions
    draft_content_service.conditions.tap do |list|
      form_ref = self
      list.define_singleton_method(:reload) do
        form_ref.draft_content_service.instance_variable_set(:@content_hash, nil)
        form_ref.draft_content_service.conditions
      end
      list.define_singleton_method(:find_by) do |attrs|
        attrs = attrs.stringify_keys
        find do |condition|
          attrs.all? { |key, value| condition.public_send(key).to_s == value.to_s }
        end
      end
    end
  end

  def draft_document_content
    draft_form_document&.content_object
  end

  def available_languages
    draft_content_service.content_hash["available_languages"] || %w[en]
  end

  def available_languages=(langs)
    update_draft_field!("available_languages", langs)
  end

  TRANSLATABLE_CY_FIELDS = %w[
    name privacy_policy_url support_email support_phone support_url support_url_text
    declaration_markdown what_happens_next_markdown payment_url
  ].freeze

  TRANSLATABLE_CY_FIELDS.each do |field|
    define_method("#{field}_cy") do
      TranslatableString.for_locale(draft_content_service.content_hash[field], locale: :cy)
    end

    define_method("#{field}_cy=") do |value|
      update_draft_translatable!(field, value, locale: :cy)
    end
  end

  def has_welsh_translation?
    available_languages.include?("cy")
  end

  def name(locale: :en)
    TranslatableString.for_locale(draft_content_service.content_hash["name"], locale:)
  end

  def name=(value, locale: :en)
    hash = draft_content_service.content_hash
    hash["name"] = TranslatableString.set_for_locale(hash["name"], locale:, string: value)
    draft_content_service.save_content!(hash)
  end

  def form_slug
    draft_content_service.content_hash["form_slug"]
  end

  def form_slug=(value)
    update_draft_field!("form_slug", value)
  end

  def submission_format_previously_changed?
    draft_field_previously_changed?("submission_format")
  end

  def send_daily_submission_batch_previously_changed?
    draft_field_previously_changed?("send_daily_submission_batch")
  end

  def send_weekly_submission_batch_previously_changed?
    draft_field_previously_changed?("send_weekly_submission_batch")
  end

  def send_copy_of_answers_previously_changed?
    draft_field_previously_changed?("send_copy_of_answers")
  end

  def submission_type
    draft_content_service.content_hash["submission_type"]
  end

  def submission_type=(value)
    update_draft_field!("submission_type", value)
  end

  def email?
    submission_type == "email"
  end

  def submission_email
    draft_content_service.content_hash["submission_email"]
  end

  def submission_email=(value)
    update_draft_field!("submission_email", value)
  end

  def submission_format
    draft_content_service.content_hash["submission_format"] || []
  end

  def submission_format=(value)
    update_draft_field!("submission_format", value)
  end

  def declaration_markdown(locale: :en)
    TranslatableString.for_locale(draft_content_service.content_hash["declaration_markdown"], locale:)
  end

  def declaration_markdown=(value, locale: :en)
    update_draft_translatable!("declaration_markdown", value, locale:)
  end

  alias_method :declaration_text, :declaration_markdown
  alias_method :declaration_text_cy, :declaration_markdown_cy
  alias_method :declaration_text_cy=, :declaration_markdown_cy=

  def what_happens_next_markdown(locale: :en)
    TranslatableString.for_locale(draft_content_service.content_hash["what_happens_next_markdown"], locale:)
  end

  def what_happens_next_markdown=(value, locale: :en)
    update_draft_translatable!("what_happens_next_markdown", value, locale:)
  end

  def privacy_policy_url(locale: :en)
    TranslatableString.for_locale(draft_content_service.content_hash["privacy_policy_url"], locale:)
  end

  def privacy_policy_url=(value, locale: :en)
    update_draft_translatable!("privacy_policy_url", value, locale:)
  end

  def support_email(locale: :en)
    TranslatableString.for_locale(draft_content_service.content_hash["support_email"], locale:)
  end

  def support_email=(value, locale: :en)
    update_draft_translatable!("support_email", value, locale:)
  end

  def support_phone(locale: :en)
    TranslatableString.for_locale(draft_content_service.content_hash["support_phone"], locale:)
  end

  def support_phone=(value, locale: :en)
    update_draft_translatable!("support_phone", value, locale:)
  end

  def support_url(locale: :en)
    TranslatableString.for_locale(draft_content_service.content_hash["support_url"], locale:)
  end

  def support_url=(value, locale: :en)
    update_draft_translatable!("support_url", value, locale:)
  end

  def support_url_text(locale: :en)
    TranslatableString.for_locale(draft_content_service.content_hash["support_url_text"], locale:)
  end

  def support_url_text=(value, locale: :en)
    update_draft_translatable!("support_url_text", value, locale:)
  end

  def payment_url(locale: :en)
    TranslatableString.for_locale(draft_content_service.content_hash["payment_url"], locale:)
  end

  def payment_url=(value, locale: :en)
    update_draft_translatable!("payment_url", value, locale:)
  end

  def send_copy_of_answers
    draft_content_service.content_hash["send_copy_of_answers"] || "disabled"
  end

  def send_copy_of_answers=(value)
    update_draft_field!("send_copy_of_answers", value)
  end

  def send_copy_of_answers_enabled?
    send_copy_of_answers == "enabled"
  end

  def send_daily_submission_batch
    draft_content_service.content_hash["send_daily_submission_batch"]
  end

  def send_daily_submission_batch=(value)
    update_draft_field!("send_daily_submission_batch", value)
  end

  def send_weekly_submission_batch
    draft_content_service.content_hash["send_weekly_submission_batch"]
  end

  def send_weekly_submission_batch=(value)
    update_draft_field!("send_weekly_submission_batch", value)
  end

  def s3_bucket_name
    draft_content_service.content_hash["s3_bucket_name"]
  end

  def s3_bucket_name=(value)
    update_draft_field!("s3_bucket_name", value)
  end

  def s3_bucket_region
    draft_content_service.content_hash["s3_bucket_region"]
  end

  def s3_bucket_region=(value)
    update_draft_field!("s3_bucket_region", value)
  end

  def s3_bucket_aws_account_id
    draft_content_service.content_hash["s3_bucket_aws_account_id"]
  end

  def s3_bucket_aws_account_id=(value)
    update_draft_field!("s3_bucket_aws_account_id", value)
  end

  def has_routing_errors
    pages.any?(&:has_routing_errors?)
  end

  alias_method :has_routing_errors?, :has_routing_errors

  def marking_complete_with_errors
    # validated via form validate callback if needed
  end

  def all_ready_for_live?(ignore_missing_welsh: false)
    task_status_service.mandatory_tasks_completed?(ignore_missing_welsh:)
  end

  delegate :all_incomplete_tasks, to: :task_status_service
  delegate :all_task_statuses, to: :task_status_service

  def group
    group_form&.group
  end

  def qualifying_route_pages
    draft_content_service.qualifying_route_steps
  end

  def has_no_remaining_routes_available?
    qualifying_route_pages.none? && conditions.any?
  end

  def page_number(page)
    draft_content_service.page_number(page)
  end

  def next_page_after(current_page)
    draft_content_service.next_step_after(current_page)
  end

  def email_confirmation_status
    return :email_set_without_confirmation if submission_email.present? && form_submission_email.blank?

    if form_submission_email.present?
      if form_submission_email.confirmed? || submission_email == form_submission_email.temporary_submission_email
        :confirmed
      else
        :sent
      end
    else
      :not_started
    end
  end

  def file_upload_question_count
    pages.count { |p| p.answer_type.to_sym == :file }
  end

  before_destroy :clear_document_pointers, prepend: true

  after_destroy do
    group_form&.destroy
  end

  def normalise_welsh!
    draft_content_service.normalise_welsh!
  end

  def draft_created?(previous_status)
    return false if lifecycle_status == previous_status.to_sym

    (previous_status.to_sym == :live && live_with_draft?) ||
      (previous_status.to_sym == :archived && archived_with_draft?)
  end

  def set_task_status_service(service)
    self.task_status_service = service
  end

  def make_live!
    self.previous_lifecycle_status = lifecycle_status
    FormDocumentOperationsService.new(self).publish!
  end

  def make_english_version_live!
    make_live!
  end

  def make_welsh_version_live!
    make_live!
  end

  def reload(*)
    draft_content_service.instance_variable_set(:@content_hash, nil)
    draft_content_service.instance_variable_set(:@content, nil)
    super
  end

  def create_draft_from_live_form!
    FormDocumentOperationsService.new(self).ensure_draft!
  end

  def create_draft_from_archived_form!
    FormDocumentOperationsService.new(self).ensure_draft!
  end

  def archive_live_form!
    FormDocumentOperationsService.new(self).archive!
  end

  def delete_draft_from_live_form!
    FormDocumentOperationsService.new(self).discard_draft!
  end

  def delete_draft_from_archived_form!
    FormDocumentOperationsService.new(self).discard_draft!
  end

  def can_make_language_live?(language:)
    language.to_s == "en" ? can_make_english_version_live? : can_make_welsh_version_live?
  end

  def can_make_english_version_live?
    has_draft_version && all_ready_for_live?(ignore_missing_welsh: true)
  end

  def can_make_welsh_version_live?
    has_draft_version && has_live_version && all_ready_for_live? && welsh_completed?
  end

  def destroy_form!
    destroy!
  end

  def clear_document_pointers
    Form.where(id: id).update_all(draft_form_document_id: nil, live_form_document_id: nil)
    self.draft_form_document_id = nil
    self.live_form_document_id = nil
  end

  def live_welsh_form_document
    return nil unless live_form_document&.content&.dig("available_languages")&.include?("cy")

    live_form_document
  end

  def draft_welsh_form_document
    draft_form_document if draft_form_document&.content&.dig("available_languages")&.include?("cy")
  end

  def archived_form_document
    live_form_document if archived?
  end

  def archived_welsh_form_document
    archived_form_document if archived? && live_form_document&.content&.dig("available_languages")&.include?("cy")
  end

private

  def set_external_id
    update(external_id: id)
  end

  def create_initial_draft_document
    return if draft_form_document_id.present?

    FormDocumentOperationsService.new(self).save_draft_content!(
      "form_id" => id.to_s,
      "name" => { "en" => "" },
      "available_languages" => %w[en],
      "form_slug" => "",
      "submission_type" => "email",
      "submission_format" => [],
      "send_copy_of_answers" => "disabled",
      "steps" => [],
    )
  end

  def update_draft_field!(key, value)
    hash = draft_content_service.content_hash
    record_draft_field_change!(key, hash[key], value)
    hash[key] = value
    draft_content_service.save_content!(hash)
  end

  def draft_field_previously_changed?(key)
    @draft_field_changes&.key?(key.to_s) || false
  end

  def record_draft_field_change!(key, old_value, new_value)
    @draft_field_changes ||= {}
    return if @draft_field_changes.key?(key.to_s)

    @draft_field_changes[key.to_s] = true if old_value != new_value
  end

  def update_draft_translatable!(key, value, locale: :en)
    hash = draft_content_service.content_hash
    hash[key] = TranslatableString.set_for_locale(hash[key], locale:, string: value)
    draft_content_service.save_content!(hash)
  end
end
