require "test_helper"

class RateLimitingTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @user = User.take
    @original_rack_attack_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rack::Attack.cache.store = @original_rack_attack_store
  end

  test "throttles after exceeding the login attempt limit from the same IP" do
    10.times do
      post session_path, params: { email_address: @user.email_address, password: "wrong" }
    end

    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_response :too_many_requests
  end

  test "does not throttle login attempts within the normal limit" do
    9.times do
      post session_path, params: { email_address: @user.email_address, password: "wrong" }
    end

    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
  end

  test "throttle is temporary and clears after the window passes" do
    11.times do
      post session_path, params: { email_address: @user.email_address, password: "wrong" }
    end
    assert_response :too_many_requests

    travel_to 3.minutes.from_now + 1.second do
      post session_path, params: { email_address: @user.email_address, password: "password" }

      assert_redirected_to root_path
    end
  end
end
