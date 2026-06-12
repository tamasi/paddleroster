class Complejo < ApplicationRecord
  has_many :users
  has_many :invitations
  has_many :canchas, dependent: :destroy

  validates :name, presence: true
end
