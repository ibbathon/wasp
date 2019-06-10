class T134FixItemsAccordingToRedesign < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :next_price_scrape, :datetime
    add_column :items, :next_data_scrape, :datetime
    remove_column :items, :last_scraped
    remove_column :items, :scrape
  end
end
