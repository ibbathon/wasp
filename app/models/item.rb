class Item < ApplicationRecord
  belongs_to :source, optional: true
  validates :endpoint, presence: true
  validates :english, presence: true
  before_save :default_values

  def default_values
    self.cost = 0 if self.cost.nil?
    self.platinum = 0 if self.platinum.nil?
    self.next_price_scrape = DateTime.new(0) if self.next_price_scrape.nil?
    self.next_data_scrape = DateTime.new(0) if self.next_data_scrape.nil?
  end
end
