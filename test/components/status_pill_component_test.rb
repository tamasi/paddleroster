require "test_helper"

class StatusPillComponentTest < ViewComponent::TestCase
  test "renders paid status" do
    render_inline(StatusPillComponent.new(status: "paid"))

    assert_selector "span", text: /Pagado/i
    assert_selector ".bg-paid-bg"
  end

  test "renders pending status" do
    render_inline(StatusPillComponent.new(status: "pending"))

    assert_selector "span", text: /Pago Pendiente/i
    assert_selector ".bg-pending-bg"
  end

  test "renders partial status" do
    render_inline(StatusPillComponent.new(status: "partial"))

    assert_selector "span", text: /Pago Parcial/i
    assert_selector ".bg-partial-bg"
  end
end
