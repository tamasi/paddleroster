require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path(email_address: @user.email_address)
    assert_nil cookies[:session_id]
  end

  test "create with wrong password shows inline error without revealing the email exists" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }
    follow_redirect!

    assert_select "#email_address_error", text: "Email o contraseña incorrectos"
  end

  test "create with nonexistent email shows the same generic inline error" do
    post session_path, params: { email_address: "no-existe@example.com", password: "wrong" }
    follow_redirect!

    assert_select "#email_address_error", text: "Email o contraseña incorrectos"
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
