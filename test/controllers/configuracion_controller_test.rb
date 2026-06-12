require "test_helper"

class ConfiguracionControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    @employee = users(:two)
  end

  test "should get show for owner" do
    sign_in_as @owner
    get configuracion_url
    assert_response :success
  end

  test "should redirect show for employee" do
    sign_in_as @employee
    get configuracion_url
    assert_redirected_to root_url
  end

  test "should update complejo" do
    sign_in_as @owner
    patch configuracion_url, params: { complejo: { name: "Nuevo Nombre", contact_info: "123456" } }
    assert_redirected_to configuracion_url
    @owner.complejo.reload
    assert_equal "Nuevo Nombre", @owner.complejo.name
    assert_equal "123456", @owner.complejo.contact_info
  end

  test "should not update complejo for employee" do
    sign_in_as @employee
    patch configuracion_url, params: { complejo: { name: "Hack" } }
    assert_redirected_to root_url
  end
end
