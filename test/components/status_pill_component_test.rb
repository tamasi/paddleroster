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

  test "renders Ofrecido for a roster entry that was offered the replacement slot" do
    entry = RosterEntry.new(confirmation_status: "pending", offered_at: 5.minutes.ago)
    render_inline(StatusPillComponent.new(status: entry.confirmation_status, context: :roster, entry: entry))

    assert_selector "span", text: /Ofrecido/i
    assert_selector ".bg-partial-bg"
  end

  test "renders Pendiente for a roster entry that was not yet offered" do
    entry = RosterEntry.new(confirmation_status: "pending")
    render_inline(StatusPillComponent.new(status: entry.confirmation_status, context: :roster, entry: entry))

    assert_selector "span", text: /Pendiente/i
    assert_selector ".bg-pending-bg"
  end
end
