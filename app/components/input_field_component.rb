# frozen_string_literal: true

# Mapea el token `{components.input-field}` de DESIGN.md: borde, fondo y radio
# (rounded-md) consistentes en modo claro/oscuro, con error inline debajo del
# campo (UX-DR1, UX-DR10).
class InputFieldComponent < ViewComponent::Base
  def initialize(label:, name:, type: "text", value: nil, error_message: nil, **html_options)
    @label = label
    @name = name
    @type = type
    @value = value
    @error_message = error_message
    @html_options = html_options
  end

  def field_id
    @field_id ||= @name.to_s.parameterize(separator: "_")
  end

  def error_id
    "#{field_id}_error"
  end

  def error?
    @error_message.present?
  end

  def input_classes
    classes = [
      "block w-full rounded-md border px-3 py-3 text-base",
      "bg-white dark:bg-gray-800",
      "focus:outline-none focus:ring-2 focus:ring-blue-600"
    ]
    classes << (error? ? "border-red-600 dark:border-red-400" : "border-gray-300 dark:border-gray-700")
    classes.join(" ")
  end

  def field_html_options
    options = @html_options.except(:type, :name, :value).merge(
      id: field_id,
      class: input_classes
    )

    if error?
      options[:"aria-invalid"] = "true"
      options[:"aria-describedby"] = error_id
    end

    options
  end
end
