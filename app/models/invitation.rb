class Invitation < ApplicationRecord
  has_secure_token

  belongs_to :complejo
  belongs_to :invited_by, class_name: "User"

  EXPIRATION_PERIOD = 7.days

  before_validation on: :create do
    self.expires_at ||= EXPIRATION_PERIOD.from_now
  end

  def expired?
    expires_at.past?
  end

  def used?
    used_at.present?
  end

  def redeemable?
    !used? && !expired?
  end
end
