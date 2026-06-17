# frozen_string_literal: true

class Player < ApplicationRecord
  has_many :complex_players, dependent: :destroy
  has_many :complejos, through: :complex_players
  has_many :roster_entries, dependent: :nullify

  validates :name, presence: true
  validates :phone, presence: true, uniqueness: true,
                    format: { with: /\A\+\d{7,15}\z/,
                              message: "debe ser formato E.164 (ej: +5491155556666)" }
end
