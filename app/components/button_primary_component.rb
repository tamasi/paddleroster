# frozen_string_literal: true

class ButtonPrimaryComponent < ViewComponent::Base
  def initialize(text: nil, type: "submit", **html_options)
    @text = text
    @type = type
    @html_options = html_options
  end

  def classes
    [
      "w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-base font-medium text-primary-foreground dark:text-primary-foreground-dark bg-primary dark:bg-primary-dark hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary dark:focus:ring-primary-dark disabled:opacity-50",
      @html_options[:class]
    ].compact.join(" ")
  end
end
