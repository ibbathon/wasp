class RemoveUnusedFields < ActiveRecord::Migration[5.2]
  def change
    remove_column :items, :source_id
    remove_column :sources, :endpoint
  end
end
