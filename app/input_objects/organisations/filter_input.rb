module Organisations
  class FilterInput < BaseInput
    attr_accessor :name, :mou_signed, :sort

    def has_filters?
      [name, mou_signed].any?(&:present?)
    end

    def sort_options
      [
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.name"), value: "name"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.users"), value: "users"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.forms"), value: "forms"),
      ]
    end

    def mou_signed_options
      [
        OpenStruct.new(label: I18n.t("organisations.index.filter.mou_signed.any")),
        OpenStruct.new(label: I18n.t("organisations.boolean.true"), value: "true"),
        OpenStruct.new(label: I18n.t("organisations.boolean.false"), value: "false"),
      ]
    end
  end
end
