class Forms::CopyOfAnswersInput < BaseInput
  attr_accessor :form, :send_copy_of_answers

  validates :send_copy_of_answers, presence: true, inclusion: { in: %w[enabled disabled] }

  def submit
    return false if invalid?

    form.send_copy_of_answers = send_copy_of_answers
    form.save_draft!
  end

  def assign_form_values
    self.send_copy_of_answers = form.send_copy_of_answers
    self
  end
end
