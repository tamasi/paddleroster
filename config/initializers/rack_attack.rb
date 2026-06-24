Rack::Attack.throttle("logins/ip", limit: 10, period: 3.minutes) do |req|
  req.ip if req.path == "/session" && req.post?
end

Rack::Attack.throttled_response_retry_after_header = true
