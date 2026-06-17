class Payment < ApplicationRecord
  belongs_to :turno
  belongs_to :registered_by, class_name: "User", optional: true

  validates :amount, presence: true, numericality: { greater_than: 0, less_than: 1_000_000 }
  validates :paid_at, presence: true
end
