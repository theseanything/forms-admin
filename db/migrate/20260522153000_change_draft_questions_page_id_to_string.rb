class ChangeDraftQuestionsPageIdToString < ActiveRecord::Migration[8.0]
  def up
    change_column :draft_questions, :page_id, :string
  end

  def down
    change_column :draft_questions, :page_id, :integer, using: "page_id::integer"
  end
end
