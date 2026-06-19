class WhatsappConnectionPolicy < ApplicationPolicy
  def show?
    user.owner?
  end

  def update?
    show?
  end
end
