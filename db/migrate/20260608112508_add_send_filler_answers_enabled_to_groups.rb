class AddSendFillerAnswersEnabledToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :send_filler_answers_enabled, :boolean, default: false
  end
end
