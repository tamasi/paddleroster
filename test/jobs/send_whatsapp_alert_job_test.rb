# frozen_string_literal: true

require "test_helper"

class SendWhatsappAlertJobTest < ActiveSupport::TestCase
  test "silently logs warning when env vars not set" do
    with_env("TELEGRAM_BOT_TOKEN" => nil, "TELEGRAM_CHAT_ID" => nil) do
      assert_nothing_raised { SendWhatsappAlertJob.new.perform("Test alert") }
    end
  end

  test "silently logs when only token is set but not chat_id" do
    with_env("TELEGRAM_BOT_TOKEN" => "fake_token", "TELEGRAM_CHAT_ID" => nil) do
      assert_nothing_raised { SendWhatsappAlertJob.new.perform("Test alert") }
    end
  end

  private

  def with_env(vars, &block)
    original = vars.transform_values { |_| ENV[_] if false }
    vars.each_key { |k| original[k] = ENV[k] }
    vars.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    original.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end
