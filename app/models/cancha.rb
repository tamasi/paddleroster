class Cancha < ApplicationRecord
  belongs_to :complejo

  enum :sport, { padel: 0, futbol_5: 1 }

  validates :name, presence: true
  validates :sport, presence: true
end
