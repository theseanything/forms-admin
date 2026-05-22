class Pages::DeleteConditionInput < ConfirmActionInput
  attr_accessor :form, :page, :record

  delegate :check_page_id, :routing_page_id, :goto_page_id, :answer_value, to: :record

  def submit
    return false if invalid?

    record.destroy_and_update_form! if confirmed?
    true
  end

  def goto_page_question_text
    return I18n.t("page_conditions.end_of_form") if goto_page_id.nil? && record.skip_to_end

    pages.filter { |p| p.id == goto_page_id }.first&.question_text
  end

  def has_secondary_skip?
    check_page = pages.find { |p| p.id.to_s == check_page_id.to_s } ||
                 raise("Cannot find page with id #{check_page_id}")
    check_page.check_conditions.any? { |c| c != record && c.routing_page_id != c.check_page_id }
  end

private

  def pages
    @pages ||= form.pages
  end
end
