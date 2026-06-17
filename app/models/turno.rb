class Turno < ApplicationRecord
  belongs_to :cancha
  belongs_to :recurring_rule, class_name: "Turno", optional: true
  has_many :recurring_instances, class_name: "Turno", foreign_key: :recurring_rule_id, dependent: :nullify
  has_many :roster_entries, -> { order(:position) }, dependent: :destroy
  has_many :payments, dependent: :destroy

  def total_paid
    payments.to_a.sum(&:amount)
  end

  accepts_nested_attributes_for :roster_entries, reject_if: proc { |attrs| attrs["name"].blank? }, allow_destroy: true

  enum :origin, { manual: 0, bot: 1 }
  enum :payment_status, { pending: 0, partial: 1, paid: 2 }
  enum :status, { active: 0, cancelled: 1 }

  validates :start_time, presence: true
  validates :reservation_name, presence: true
  validates :price, numericality: { greater_than: 0, allow_nil: true }
  validates :start_time, uniqueness: { scope: :cancha_id, conditions: -> { where.not(status: :cancelled) }, message: "ya tiene un turno reservado en este horario" }
end
