# frozen_string_literal: true

require "test_helper"

class InputFieldComponentTest < ViewComponent::TestCase
  def test_renders_label_and_input_without_error
    render_inline(InputFieldComponent.new(label: "Email", name: "email_address", type: "email", value: "user@example.com"))

    assert_selector "label[for='email_address']", text: "Email"
    assert_selector "input#email_address[type='email'][name='email_address'][value='user@example.com']"
    assert_no_selector "p[id='email_address_error']"
  end

  def test_renders_inline_error_message_below_field
    render_inline(InputFieldComponent.new(label: "Email", name: "email_address", type: "email", value: "", error_message: "Email inválido"))

    assert_selector "input#email_address[aria-invalid='true'][aria-describedby='email_address_error']"
    assert_selector "p#email_address_error", text: "Email inválido"
  end

  def test_password_value_is_never_rendered
    render_inline(InputFieldComponent.new(label: "Contraseña", name: "password", type: "password", value: "secret"))

    assert_selector "input#password[type='password']"
    assert_no_selector "input[value='secret']"
  end
end
