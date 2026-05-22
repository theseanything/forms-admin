# frozen_string_literal: true

module TranslatableString
  SUPPORTED_LOCALES = %w[en cy].freeze

  module_function

  def normalize(value)
    case value
    when nil
      {}
    when String
      { "en" => value }
    when Hash
      value.stringify_keys.slice(*SUPPORTED_LOCALES)
    else
      {}
    end
  end

  def for_locale(value, locale:)
    normalize(value)[locale.to_s]
  end

  def set_for_locale(value, locale:, string:)
    map = normalize(value)
    if string.present?
      map[locale.to_s] = string
    else
      map.delete(locale.to_s)
    end
    map
  end

  def merge_locales(en_value:, cy_value: nil)
    result = {}
    result["en"] = en_value if en_value.present?
    result["cy"] = cy_value if cy_value.present?
    result
  end

  def normalise_welsh!(map, english_key:)
    return map unless map.is_a?(Hash)

    map["cy"] = nil if map["en"].blank?
    map.compact
  end
end
