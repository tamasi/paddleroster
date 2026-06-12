class RosterEntry < ApplicationRecord
  belongs_to :turno

  enum :role, { titular: 0, suplente: 1 }
  enum :confirmation_status, { pending: 0, confirmed: 1, replacement: 2, uncovered: 3 }

  validates :name, presence: true
end
