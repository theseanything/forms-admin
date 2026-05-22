class Forms::DeleteWelshTranslationInput < DeleteConfirmationInput
  attr_accessor :form

  def submit
    return false if invalid?

    reset_translations if confirmed?
    true
  end

  def submit_without_confirm
    reset_translations
    true
  end

private

  def reset_translations
    FormDocumentOperationsService.new(form).remove_welsh!
    form.save_draft!
  end
end
