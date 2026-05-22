module ConditionMethods
  def is_exit_page?
    markdown = TranslatableString.normalize(exit_page_markdown)
    heading = TranslatableString.normalize(exit_page_heading)
    markdown.values.any?(&:present?) || heading.values.any?(&:present?)
  end

  alias_method :exit_page?, :is_exit_page?

  def secondary_skip?
    answer_value.blank? && check_page_id != routing_page_id
  end
end
