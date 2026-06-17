# frozen_string_literal: true

class ReportPolicy < ApplicationPolicy
  def index?
    user&.owner?
  end
end
