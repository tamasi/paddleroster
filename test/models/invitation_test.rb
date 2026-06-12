require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  setup do
    @complejo = complejos(:piloto)
    @owner = users(:one)
  end

  test "generates a unique token automatically on create" do
    invitation = Invitation.create!(complejo: @complejo, invited_by: @owner)

    assert_not_nil invitation.token
  end

  test "sets expires_at to 7 days from now by default" do
    invitation = Invitation.create!(complejo: @complejo, invited_by: @owner)

    assert_in_delta 7.days.from_now, invitation.expires_at, 1.minute
  end

  test "is redeemable when not used and not expired" do
    invitation = Invitation.create!(complejo: @complejo, invited_by: @owner)

    assert_not invitation.expired?
    assert_not invitation.used?
    assert invitation.redeemable?
  end

  test "is not redeemable when used" do
    invitation = Invitation.create!(complejo: @complejo, invited_by: @owner, used_at: Time.current)

    assert invitation.used?
    assert_not invitation.redeemable?
  end

  test "is not redeemable when expired" do
    invitation = Invitation.create!(complejo: @complejo, invited_by: @owner, expires_at: 1.day.ago)

    assert invitation.expired?
    assert_not invitation.redeemable?
  end
end
