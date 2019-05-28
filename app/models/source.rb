class Source < ApplicationRecord
  has_many :item
  validates :endpoint, presence: true
  validates :english, presence: true
end
