# frozen_string_literal: true

class FormDocument::Step
  include ActiveModel::API
  include ActiveModel::Attributes

  attr_reader :routing_conditions

  attribute :id, :string
  attribute :data, DataStructType.new
  attribute :type, :string
  attribute :position, :integer
  attribute :next_step_id, :string
  attribute :question_text, TranslatableStringType.new
  attribute :hint_text, TranslatableStringType.new
  attribute :page_heading, TranslatableStringType.new
  attribute :guidance_markdown, TranslatableStringType.new
  attribute :answer_type, :string

  delegate_missing_to :data

  def initialize(attributes = {})
    attrs = attributes.stringify_keys
    @routing_conditions = Array(attrs.fetch("routing_conditions", [])).map { |condition| FormDocument::Condition.new(**condition) }
    attrs.slice!(*self.class.attribute_names)
    super(attrs)
  end

  def is_optional?
    ActiveRecord::Type::Boolean.new.cast(data.is_optional) || false
  end

  def is_repeatable?
    ActiveRecord::Type::Boolean.new.cast(data.is_repeatable) || false
  end

  def question_text_for(locale = :en)
    TranslatableString.for_locale(question_text, locale:)
  end

  def to_content_hash
    {
      "id" => id,
      "type" => type || "question",
      "position" => position,
      "next_step_id" => next_step_id,
      "question_text" => TranslatableString.normalize(question_text),
      "hint_text" => TranslatableString.normalize(hint_text),
      "page_heading" => TranslatableString.normalize(page_heading),
      "guidance_markdown" => TranslatableString.normalize(guidance_markdown),
      "answer_type" => answer_type,
      "data" => {
        "is_optional" => is_optional?,
        "is_repeatable" => is_repeatable?,
        "answer_settings" => data.answer_settings,
      }.compact,
      "routing_conditions" => routing_conditions.map(&:to_content_hash),
    }
  end
end
