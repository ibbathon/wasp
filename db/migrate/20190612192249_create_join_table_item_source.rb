class CreateJoinTableItemSource < ActiveRecord::Migration[5.2]
  def change
    create_join_table :items, :sources do |t|
      t.index [:item_id, :source_id]
    end
  end
end
