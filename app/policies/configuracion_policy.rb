class ConfiguracionPolicy < ApplicationPolicy
  def show?
    user.owner?
  end

  def edit?
    show?
  end

  def update?
    show?
  end

  class Scope < ApplicationPolicy::Scope
  end
end
