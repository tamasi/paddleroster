# frozen_string_literal: true

class OccupancyBarComponent < ViewComponent::Base
  def initialize(label:, percentage:)
    @label = label
    @percentage = percentage.to_i.clamp(0, 100)
  end

  def percentage
    @percentage
  end

  def label
    @label
  end
end
