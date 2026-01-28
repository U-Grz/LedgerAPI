class JsonWebToken
  # Secret key for signing tokens
  # In production, store this in Rails credentials or environment variable
  SECRET_KEY = Rails.application.credentials.secret_key_base || 'fallback-secret-key-for-development'
  
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end
  
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError => e
    nil
  end
end
