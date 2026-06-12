require_relative "application_system_test_case"

class DarkModeTest < ApplicationSystemTestCase
  setup do
    visit new_session_path
    fill_in "email_address", with: users(:one).email_address
    fill_in "password", with: "password"
    click_on "Ingresar"
  end

  test "toggling dark mode applies the dark class and persists across reload" do
    assert_no_selector "html.dark"

    find("[data-controller='dark-mode-toggle']").click
    assert_selector "html.dark"

    visit current_path
    assert_selector "html.dark"

    find("[data-controller='dark-mode-toggle']").click
    assert_no_selector "html.dark"
  end
end
