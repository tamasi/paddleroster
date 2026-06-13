class Complejo < ApplicationRecord
  # Horario operativo por defecto del MVP (14:00 a 23:00, slots de 1 hora).
  HORARIO_OPERATIVO = (14..23)

  has_many :users
  has_many :invitations
  has_many :canchas, dependent: :destroy

  validates :name, presence: true
end
