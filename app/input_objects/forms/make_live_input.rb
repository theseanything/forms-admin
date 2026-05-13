class Forms::MakeLiveInput < ConfirmActionInput
  attr_accessor :form, :language

  validate :required_parts_of_form_completed

private

  def required_parts_of_form_completed
    # we are valid and didn't need to save
    return unless confirmed?
    return if form.all_ready_for_live?(ignore_missing_welsh:)

    form.all_incomplete_tasks(ignore_missing_welsh:).each do |section|
      errors.add(:confirm, section.to_sym)
    end

    errors.empty?
  end

  def ignore_missing_welsh
    # Ignore missing Welsh if we're only making the English version live
    language == "en"
  end
end
