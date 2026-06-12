# frozen_string_literal: true

require "test_helper"

class AppHeaderComponentTest < ViewComponent::TestCase
  def test_employee_does_not_see_configuracion_link
    employee = users(:two)

    render_inline(AppHeaderComponent.new(current_user: employee, title: "Inicio"))

    assert_selector "h1", text: "Inicio"
    assert_text employee.email_address
    assert_no_selector "a", text: "Configuración", visible: false
    assert_selector "button", text: "Cerrar sesión", visible: false
  end

  def test_owner_sees_configuracion_link
    owner = users(:one)

    render_inline(AppHeaderComponent.new(current_user: owner, title: "Inicio"))

    assert_selector "a", text: "Configuración", visible: false
  end

  def test_renders_dark_mode_toggle
    render_inline(AppHeaderComponent.new(current_user: users(:one), title: "Inicio"))

    assert_selector "[data-controller='dark-mode-toggle']"
  end
end
