class Item < ApplicationRecord
  has_and_belongs_to_many :sources
  validates :endpoint, presence: true
  validates_uniqueness_of :endpoint
  validates :english, presence: true
  validates_uniqueness_of :english
  before_save :default_values

  def default_values
    self.cost = 0 if self.cost.nil?
    self.platinum = 0 if self.platinum.nil?
    self.next_price_scrape = DateTime.new(0) if self.next_price_scrape.nil?
    self.next_data_scrape = DateTime.new(0) if self.next_data_scrape.nil?
  end
end
