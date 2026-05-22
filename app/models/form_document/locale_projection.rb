# frozen_string_literal: true

class FormDocument::LocaleProjection
  TRANSLATABLE_STEP_KEYS = %w[question_text hint_text page_heading guidance_markdown].freeze
  TRANSLATABLE_CONDITION_KEYS = %w[exit_page_heading exit_page_markdown].freeze
  TRANSLATABLE_CONTENT_KEYS = %w[
    name
    privacy_policy_url
    support_email
    support_phone
    support_url
    support_url_text
    declaration_text
    declaration_markdown
    what_happens_next_markdown
    payment_url
  ].freeze

  def self.project(content, language: "en")
    new(content, language:).project
  end

  def initialize(content, language: "en")
    @content = content.deep_stringify_keys
    @language = language.to_s
  end

  def project
    result = @content.deep_dup
    result["language"] = @language

    TRANSLATABLE_CONTENT_KEYS.each do |key|
      result[key] = project_value(result[key]) if result.key?(key)
    end

    result["steps"] = Array(result["steps"]).map { |step| project_step(step) }
    result
  end

private

  def project_value(value)
    return value unless value.is_a?(Hash) && value.keys.intersect?(TranslatableString::SUPPORTED_LOCALES)

    value[@language] || value["en"]
  end

  def project_step(step)
    projected = step.deep_dup
    TRANSLATABLE_STEP_KEYS.each do |key|
      projected[key] = project_value(projected[key]) if projected.key?(key)
    end

    if projected["data"].is_a?(Hash)
      projected["data"] = project_step_data(projected["data"])
    end

    projected["routing_conditions"] = Array(projected["routing_conditions"]).map { |c| project_condition(c) }
    projected
  end

  def project_step_data(data)
    data = data.deep_dup
    TRANSLATABLE_STEP_KEYS.each do |key|
      data[key] = project_value(data[key]) if data.key?(key)
    end
    if data["answer_settings"].is_a?(Hash)
      data["answer_settings"] = project_answer_settings(data["answer_settings"])
    end
    data
  end

  def project_answer_settings(settings)
    settings = settings.deep_dup
    if settings["selection_options"].is_a?(Array)
      settings["selection_options"] = settings["selection_options"].map do |option|
        option = option.deep_dup
        option["name"] = project_value(option["name"]) if option["name"].is_a?(Hash)
        option
      end
    end
    if settings["none_of_the_above_question"].is_a?(Hash)
      nota = settings["none_of_the_above_question"]
      nota["question_text"] = project_value(nota["question_text"]) if nota["question_text"].is_a?(Hash)
    end
    settings
  end

  def project_condition(condition)
    projected = condition.deep_dup
    TRANSLATABLE_CONDITION_KEYS.each do |key|
      projected[key] = project_value(projected[key]) if projected.key?(key)
    end
    projected
  end
end
