class Item < ApplicationRecord
  belongs_to :source
  validates :endpoint, presence: true
  validates :english, presence: true
  before_save :default_values

  def default_values
    self.cost = 0 if self.cost.nil?
    self.scrape = false if self.scrape.nil?
    self.platinum = 0 if self.platinum.nil?
    self.last_scraped = DateTime.new(0) if self.last_scraped.nil?
  end
end
