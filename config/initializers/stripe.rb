Rails.configuration.to_prepare do
	Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key)
end