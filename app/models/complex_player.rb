# frozen_string_literal: true

class ComplexPlayer < ApplicationRecord
  belongs_to :player
  belongs_to :complejo

  validates :player_id, uniqueness: { scope: :complejo_id,
                                      message: "ya está asociado a este complejo" }
end
