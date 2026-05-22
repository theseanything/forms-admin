# frozen_string_literal: true

class TranslatableStringType < ActiveModel::Type::Value
  def type
    :translatable_string
  end

  def cast(value)
    TranslatableString.normalize(value)
  end

  def serialize(value)
    cast(value)
  end
end
