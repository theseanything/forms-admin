# frozen_string_literal: true

class FormDocument::Content
  include ActiveModel::API
  include ActiveModel::Attributes

  attr_reader :steps

  attribute :form_id, :string
  attribute :live_at, :datetime
  attribute :first_made_live_at, :datetime
  attribute :name, TranslatableStringType.new
  attribute :available_languages, default: -> { %w[en] }
  attribute :form_slug, :string
  attribute :created_at, :datetime
  attribute :creator_id, :integer
  attribute :start_page, :string
  attribute :updated_at, :datetime
  attribute :payment_url, TranslatableStringType.new
  attribute :support_url, TranslatableStringType.new
  attribute :support_email, TranslatableStringType.new
  attribute :support_phone, TranslatableStringType.new
  attribute :s3_bucket_name, :string
  attribute :submission_type, :string
  attribute :submission_format, default: -> { [] }
  attribute :declaration_text, TranslatableStringType.new
  attribute :declaration_markdown, TranslatableStringType.new
  attribute :s3_bucket_region, :string
  attribute :submission_email, :string
  attribute :support_url_text, TranslatableStringType.new
  attribute :privacy_policy_url, TranslatableStringType.new
  attribute :s3_bucket_aws_account_id, :string
  attribute :what_happens_next_markdown, TranslatableStringType.new
  attribute :send_daily_submission_batch, :boolean
  attribute :send_weekly_submission_batch, :boolean
  attribute :send_copy_of_answers, :string

  alias_attribute :id, :form_id

  def initialize(attributes = {})
    attrs = attributes.stringify_keys
    @steps = Array(attrs.fetch("steps", [])).map { |step| FormDocument::Step.new(**step) }
    attrs.slice!(*self.class.attribute_names)
    super(attrs)
  end

  def made_live_date
    first_made_live_at&.to_date
  end

  def self.from_form_document(form_document)
    new(**form_document.content)
  end

  def has_welsh_translation?
    available_languages.present? && available_languages.include?("cy")
  end

  def name(locale = :en)
    translatable_string_for("name", locale:)
  end

  def name_for(locale = :en)
    name(locale)
  end

  def declaration_markdown(locale = :en)
    translatable_string_for("declaration_markdown", locale:)
  end

  def declaration_markdown_for(locale = :en)
    declaration_markdown(locale)
  end

  def what_happens_next_markdown(locale = :en)
    translatable_string_for("what_happens_next_markdown", locale:)
  end

  def what_happens_next_markdown_for(locale = :en)
    what_happens_next_markdown(locale)
  end

  def payment_url(locale = :en)
    translatable_string_for("payment_url", locale:)
  end

  def payment_url_for(locale = :en)
    payment_url(locale)
  end

  def privacy_policy_url(locale = :en)
    translatable_string_for("privacy_policy_url", locale:)
  end

  def support_email(locale = :en)
    translatable_string_for("support_email", locale:)
  end

  def support_phone(locale = :en)
    translatable_string_for("support_phone", locale:)
  end

  def support_url(locale = :en)
    translatable_string_for("support_url", locale:)
  end

  def support_url_text(locale = :en)
    translatable_string_for("support_url_text", locale:)
  end

  def to_content_hash
    hash = attributes.stringify_keys
    hash["steps"] = @steps.map(&:to_content_hash)
    hash["form_id"] = form_id.to_s
    hash
  end

private

  def translatable_string_for(attribute, locale:)
    TranslatableString.for_locale(attributes[attribute], locale:)
  end
end
