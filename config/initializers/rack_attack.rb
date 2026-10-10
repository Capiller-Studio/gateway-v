# frozen_string_literal: true

class Rack::Attack
  ### Throttles ###

  # Unauthenticated requests — strict limit (login, register, etc.)
  throttle('unauthenticated/ip', limit: 20, period: 1.minute) do |req|
    unless req.env['HTTP_AUTHORIZATION'].present? || req.env['HTTP_X_API_KEY'].present?
      req.ip
    end
  end

  # Login/registration brute force protection
  throttle('auth_attempts/ip', limit: 10, period: 1.minute) do |req|
    if req.post? && (req.path.include?('/sessions') || req.path.include?('/registrations'))
      req.ip
    end
  end

  # Authenticated requests — generous limit per API key
  throttle('authenticated/api_key', limit: 1000, period: 1.minute) do |req|
    req.env['HTTP_X_API_KEY'] if req.env['HTTP_X_API_KEY'].present?
  end

  # Authenticated requests — generous limit per JWT user (by IP as fallback)
  throttle('authenticated/jwt', limit: 300, period: 1.minute) do |req|
    if req.env['HTTP_AUTHORIZATION'].present?
      req.ip
    end
  end

  ### Responses ###

  self.throttled_responder = lambda do |env|
    retry_after = (env['rack.attack.match_data'] || {})[:period]

    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s
      },
      [{
        success: false,
        errors: [{
          code: "rate_limit_exceeded",
          message: "Too many requests. Please retry after #{retry_after} seconds."
        }]
      }.to_json]
    ]
  end
end
