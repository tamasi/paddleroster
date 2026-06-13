class Cancha < ApplicationRecord
  belongs_to :complejo
  has_many :turnos, dependent: :destroy

  broadcasts_to :complejo, target: ->(cancha) { ActionView::RecordIdentifier.dom_id(cancha.complejo, :canchas) }

  enum :sport, { padel: 0, futbol_5: 1 }

  validates :name, presence: true
  validates :sport, presence: true
end
