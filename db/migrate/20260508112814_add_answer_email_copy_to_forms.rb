class AddAnswerEmailCopyToForms < ActiveRecord::Migration[8.1]
  def change
    add_column :forms, :send_copy_of_answers, :string, null: false, default: "disabled"
  end
end
