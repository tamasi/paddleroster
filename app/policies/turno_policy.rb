class TurnoPolicy < ApplicationPolicy
  def new?
    user&.complejo.present?
  end

  def create?
    user&.complejo.present?
  end

  def mark_recurring?
    user&.owner?
  end

  def show?
    user&.complejo.present? && record.cancha.complejo_id == user.complejo_id
  end

  def update?
    user&.complejo.present? && record.cancha.complejo_id == user.complejo_id
  end

  def cancel?
    user&.complejo.present? && record.cancha.complejo_id == user.complejo_id
  end
end
