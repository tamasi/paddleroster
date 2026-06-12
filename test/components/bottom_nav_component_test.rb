# frozen_string_literal: true

require "test_helper"

class BottomNavComponentTest < ViewComponent::TestCase
  def test_employee_sees_three_items_without_reportes
    employee = users(:two)

    render_inline(BottomNavComponent.new(current_user: employee, current_path: "/"))

    assert_selector "a", text: "Inicio"
    assert_selector "a", text: "Calendario"
    assert_selector "a", text: "Pagos"
    assert_no_selector "a", text: "Reportes"
  end

  def test_owner_sees_four_items_including_reportes
    owner = users(:one)

    render_inline(BottomNavComponent.new(current_user: owner, current_path: "/"))

    assert_selector "a", text: "Inicio"
    assert_selector "a", text: "Calendario"
    assert_selector "a", text: "Pagos"
    assert_selector "a", text: "Reportes"
  end

  def test_marks_the_current_item_as_active
    owner = users(:one)

    render_inline(BottomNavComponent.new(current_user: owner, current_path: "/calendario"))

    assert_selector "a.text-primary", text: "Calendario"
    assert_selector "a.text-text-secondary", text: "Inicio"
  end
end
