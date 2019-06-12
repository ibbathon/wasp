class Source < ApplicationRecord
  has_and_belongs_to_many :items
  validates :english, presence: true
  validates_uniqueness_of :english
end
