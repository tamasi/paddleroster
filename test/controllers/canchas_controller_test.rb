require "test_helper"

class CanchasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    @complejo = complejos(:piloto)
    @cancha = canchas(:one)
  end

  test "should create cancha" do
    sign_in_as @owner
    assert_difference("Cancha.count") do
      post configuracion_canchas_url, params: { cancha: { name: "Nueva Cancha", sport: "padel" } }
    end
    assert_redirected_to configuracion_url
  end

  test "create with invalid sport re-renders new with error" do
    sign_in_as @owner

    assert_no_difference("Cancha.count") do
      post configuracion_canchas_url, params: { cancha: { name: "Nueva Cancha", sport: "tenis" } }
    end

    assert_response :unprocessable_entity
  end

  test "should update cancha" do
    sign_in_as @owner
    patch configuracion_cancha_url(@cancha), params: { cancha: { name: "Nombre Editado" } }
    assert_redirected_to configuracion_url
    @cancha.reload
    assert_equal "Nombre Editado", @cancha.name
  end

  test "update with invalid sport re-renders edit with error" do
    sign_in_as @owner

    patch configuracion_cancha_url(@cancha), params: { cancha: { name: @cancha.name, sport: "tenis" } }

    assert_response :unprocessable_entity
    assert_not_equal "tenis", @cancha.reload.sport
  end

  test "should destroy cancha" do
    sign_in_as @owner
    assert_difference("Cancha.count", -1) do
      delete configuracion_cancha_url(@cancha)
    end
    assert_redirected_to configuracion_url
  end
end
