class CreateItems < ActiveRecord::Migration[5.2]
  def change
    create_table :items do |t|
      t.string :endpoint
      t.string :english
      t.references :source
      t.integer :cost
      t.boolean :scrape
      t.integer :platinum
      t.datetime :last_scraped

      t.timestamps
    end
  end
end
