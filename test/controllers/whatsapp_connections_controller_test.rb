require "test_helper"

class WhatsappConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    @employee = users(:two)
    @complejo = complejos(:piloto)
  end

  test "owner sees the connection status" do
    sign_in_as @owner
    get configuracion_whatsapp_connection_url
    assert_response :success
  end

  test "show lazily creates the connection for the complejo" do
    sign_in_as @owner
    assert_difference("WhatsappConnection.count", 1) do
      get configuracion_whatsapp_connection_url
    end
    assert WhatsappConnection.find_by(complejo: @complejo).disconnected?
  end

  test "owner can request a connection" do
    sign_in_as @owner
    post connect_configuracion_whatsapp_connection_url
    assert_redirected_to configuracion_url
    assert_equal "connect", WhatsappConnection.find_by(complejo: @complejo).requested_action
  end

  test "owner can request a disconnection" do
    sign_in_as @owner
    WhatsappConnection.create!(complejo: @complejo, status: "connected", phone: "+5491100000000")
    post disconnect_configuracion_whatsapp_connection_url
    assert_redirected_to configuracion_url
    assert_equal "disconnect", WhatsappConnection.find_by(complejo: @complejo).requested_action
  end

  test "employee is denied access by direct URL" do
    sign_in_as @employee
    get configuracion_whatsapp_connection_url
    assert_redirected_to root_path
  end

  test "employee cannot request a connection by direct URL" do
    sign_in_as @employee
    post connect_configuracion_whatsapp_connection_url
    assert_redirected_to root_path
  end
end
