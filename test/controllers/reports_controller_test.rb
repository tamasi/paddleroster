require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  test "index requires authentication" do
    get reportes_path

    assert_redirected_to new_session_path
  end

  test "index renders for an authenticated user" do
    sign_in_as(User.take)

    get reportes_path

    assert_response :success
  end
end
