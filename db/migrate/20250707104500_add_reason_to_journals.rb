class AddReasonToJournals < ActiveRecord::Migration[5.2]
  def change
    add_column :journals, :reason, :text
  end
end
