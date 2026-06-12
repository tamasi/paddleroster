require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  test "owner can create an invitation" do
    owner = users(:one)
    sign_in_as(owner)

    assert_difference "Invitation.count", 1 do
      post invitations_path
    end

    invitation = Invitation.last
    assert_equal owner.complejo, invitation.complejo
    assert_equal owner, invitation.invited_by
    assert_redirected_to configuracion_path
    assert_match invitation.token, flash[:notice]
  end

  test "employee cannot create an invitation" do
    employee = users(:two)
    sign_in_as(employee)

    assert_no_difference "Invitation.count" do
      post invitations_path
    end

    assert_redirected_to root_path
  end

  test "unauthenticated user cannot create an invitation" do
    assert_no_difference "Invitation.count" do
      post invitations_path
    end

    assert_redirected_to new_session_path
  end

  test "valid invitation shows the registration form" do
    invitation = Invitation.create!(complejo: complejos(:piloto), invited_by: users(:one))

    get invitation_path(invitation.token)

    assert_response :success
    assert_select "form"
  end

  test "valid invitation creates an employee account, signs in and marks invitation as used" do
    invitation = Invitation.create!(complejo: complejos(:piloto), invited_by: users(:one))

    assert_difference "User.count", 1 do
      patch invitation_path(invitation.token), params: {
        user: { email_address: "nuevo@example.com", password: "password", password_confirmation: "password" }
      }
    end

    user = User.find_by(email_address: "nuevo@example.com")
    assert user.employee?
    assert_equal complejos(:piloto), user.complejo

    assert invitation.reload.used?
    assert_not_nil cookies["session_id"]
    assert_redirected_to root_path
  end

  test "expired invitation rejects registration and shows error message" do
    invitation = Invitation.create!(complejo: complejos(:piloto), invited_by: users(:one), expires_at: 1.day.ago)

    get invitation_path(invitation.token)
    assert_response :success
    assert_select "form", false

    assert_no_difference "User.count" do
      patch invitation_path(invitation.token), params: {
        user: { email_address: "nuevo@example.com", password: "password", password_confirmation: "password" }
      }
    end
  end

  test "registration with an already taken email shows a validation error" do
    invitation = Invitation.create!(complejo: complejos(:piloto), invited_by: users(:one))

    assert_no_difference "User.count" do
      patch invitation_path(invitation.token), params: {
        user: { email_address: users(:two).email_address, password: "password", password_confirmation: "password" }
      }
    end

    assert_response :unprocessable_entity
    assert_not invitation.reload.used?
  end

  test "used invitation cannot be redeemed twice" do
    invitation = Invitation.create!(complejo: complejos(:piloto), invited_by: users(:one), used_at: Time.current)

    assert_no_difference "User.count" do
      patch invitation_path(invitation.token), params: {
        user: { email_address: "otro@example.com", password: "password", password_confirmation: "password" }
      }
    end

    get invitation_path(invitation.token)
    assert_select "form", false
  end
end
