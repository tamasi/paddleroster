require "test_helper"

class SessionExpirationTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "visiting a protected page without ever signing in redirects to login without the expiration warning" do
    get root_path

    assert_redirected_to new_session_path
    follow_redirect!

    assert_select "#warning", count: 0
  end

  test "an expired session redirects to login with a warning and returns to the original page after re-authenticating" do
    sign_in_as(@user)
    Session.delete_all

    get "/?ref=test"

    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "#warning", text: "Tu sesión expiró, iniciá sesión de nuevo"

    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to "/?ref=test"
  end
end
