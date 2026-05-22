# frozen_string_literal: true

class FormStep
  ANSWER_TYPES = %w[name organisation_name email phone_number national_insurance_number address date selection number text file].freeze
  ANSWER_TYPES_WITHOUT_SETTINGS = %w[organisation_name email phone_number national_insurance_number number].freeze
  ANSWER_TYPES_WITH_SETTINGS = %w[selection text date address name].freeze

  attr_reader :form, :id, :step_data, :draft_service

  delegate :save_question_changes!, to: :draft_service

  def initialize(form:, step_data:, draft_service:)
    @form = form
    @step_data = step_data.deep_stringify_keys
    @id = @step_data["id"]
    @draft_service = draft_service
  end

  def position
    @step_data["position"].to_i
  end

  def answer_type
    @step_data["answer_type"]
  end

  def question_text(locale: :en)
    TranslatableString.for_locale(@step_data["question_text"], locale:)
  end

  def question_text_cy
    question_text(locale: :cy)
  end

  def question_text_cy=(value)
    @step_data["question_text"] = TranslatableString.set_for_locale(@step_data["question_text"], locale: :cy, string: value)
  end

  def hint_text_cy
    hint_text(locale: :cy)
  end

  def hint_text_cy=(value)
    @step_data["hint_text"] = TranslatableString.set_for_locale(@step_data["hint_text"], locale: :cy, string: value)
  end

  def page_heading_cy
    page_heading(locale: :cy)
  end

  def page_heading_cy=(value)
    @step_data["page_heading"] = TranslatableString.set_for_locale(@step_data["page_heading"], locale: :cy, string: value)
  end

  def guidance_markdown_cy
    guidance_markdown(locale: :cy)
  end

  def guidance_markdown_cy=(value)
    @step_data["guidance_markdown"] = TranslatableString.set_for_locale(@step_data["guidance_markdown"], locale: :cy, string: value)
  end

  def answer_settings_cy
    @step_data.dig("data", "answer_settings")
  end

  def hint_text(locale: :en)
    TranslatableString.for_locale(@step_data["hint_text"], locale:)
  end

  def page_heading(locale: :en)
    TranslatableString.for_locale(@step_data["page_heading"], locale:)
  end

  def guidance_markdown(locale: :en)
    TranslatableString.for_locale(@step_data["guidance_markdown"], locale:)
  end

  def is_optional?
    ActiveRecord::Type::Boolean.new.cast(data["is_optional"]) || false
  end

  alias_method :optional?, :is_optional?

  def is_repeatable?
    ActiveRecord::Type::Boolean.new.cast(data["is_repeatable"]) || false
  end

  def data
    @step_data["data"] || {}
  end

  def answer_settings
    settings = data["answer_settings"]
    settings.is_a?(DataStruct) ? settings : DataStruct.new(settings || {})
  end

  def routing_conditions
    Array(@step_data["routing_conditions"]).map do |c|
      FormCondition.new(form:, condition: c, step_id: id)
    end
  end

  def self.create_and_update_form!(form_id:, **attrs)
    form = Form.find(form_id)
    position = form.draft_content_service.steps.length + 1
    form.draft_content_service.add_step!(attrs.merge(form_id:, position:))
  end

  def check_conditions
    draft_service.conditions.select { |c| c.check_page_id == id }
  end

  def goto_conditions
    draft_service.conditions.select { |c| c.goto_page_id == id }
  end

  def only_one_option?
    ActiveModel::Type::Boolean.new.cast(answer_settings.try(:[], "only_one_option") || answer_settings.try(:only_one_option))
  end

  def has_routing_errors
    routing_conditions.any?(&:has_routing_errors?)
  end

  alias_method :has_routing_errors?, :has_routing_errors

  def question_with_number
    "#{position}. #{question_text}"
  end

  def show_optional_suffix?
    is_optional? && answer_type != "selection"
  end

  def page_position_id
    "page-#{position}"
  end

  def external_id
    id
  end

  def next_page
    @step_data["next_step_id"]
  end

  def has_next_page?
    next_page.present?
  end

  def save_and_update_form
    draft_service.save_question_changes!
    true
  end

  def destroy_and_update_form!
    draft_service.destroy_step!(id)
    true
  end

  def move_page(direction)
    draft_service.move_step!(id, direction)
  end

  def assign_attributes(**attrs)
    attrs = attrs.stringify_keys
    %w[question_text hint_text page_heading guidance_markdown].each do |key|
      attrs[key] = { "en" => attrs[key] } if attrs[key].is_a?(String)
    end
    attrs["data"] = {
      "is_optional" => attrs.delete("is_optional"),
      "is_repeatable" => attrs.delete("is_repeatable"),
      "answer_settings" => attrs.delete("answer_settings"),
    }.compact
    draft_service.update_step!(id, @step_data.merge(attrs))
    self
  end

  def update!(attrs)
    assign_attributes(**attrs)
  end

  def secondary_skip_condition
    check_conditions.find { |c| c.answer_value.blank? && c.check_page_id != c.routing_page_id }
  end

  def as_json(options = {})
    {
      id:,
      position:,
      question_text: question_text,
      answer_type:,
      is_optional: is_optional?,
      is_repeatable: is_repeatable?,
      routing_conditions: routing_conditions.map(&:as_json),
    }
  end
end

# Legacy alias for specs and gradual migration
Page = FormStep unless defined?(Page)
