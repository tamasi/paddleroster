require "test_helper"

class OccupancyBarComponentTest < ViewComponent::TestCase
  test "renders the label and the percentage as text" do
    render_inline(OccupancyBarComponent.new(label: "Cancha 1 — Pádel", percentage: 75))

    assert_text "Cancha 1 — Pádel"
    assert_text "75%"
    assert_selector "div[style='width: 75%']"
  end

  test "clamps percentages above 100 to 100" do
    render_inline(OccupancyBarComponent.new(label: "Cancha 1", percentage: 150))

    assert_text "100%"
    assert_selector "div[style='width: 100%']"
  end

  test "clamps negative percentages to 0" do
    render_inline(OccupancyBarComponent.new(label: "Cancha 1", percentage: -10))

    assert_text "0%"
    assert_selector "div[style='width: 0%']"
  end
end
