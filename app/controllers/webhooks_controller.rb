class WebhooksController < ApplicationController
	skip_before_action :verify_authenticity_token

	def stripe
		payload = request.body.read
		sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
		endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)

		begin
			event = Stripe::Webhook.construct_event(
				payload, sig_header, endpoint_secret
			)
		rescue JSON::ParserError => e
			render json: { error: "Invalid payload" }, status: 400
			return
		rescue Stripe::SignatureVerificationError => e
			render json: { error: "Invalid signature" }, status: 400
			return
		end

		case event.type
		when "checkout.session.completed"
			handle_checkout_session_completed(event.data.object)
		when "customer.subscription.updated"
			handle_subscription_updated(event.data.object)
		when "customer.subscription.deleted"
			handle_subscription_deleted(event.data.object)
		when "invoice.payment_succeeded"
			handle_payment_succeeded(event.data.object)
		when "invoice.payment_failed"
			handle_payment_failed(event.data.object)
		end

		render json: { message: "success" }
	end

	private

	def handle_checkout_session_comleted(session)
		user_id = session.subscription_metadata&.user_id || session.client_reference_id
		return unless user_id

		user = User.find_by(id: user_id)
		return unless user

		subscription_data = Stripe::Subscription.retrieve(session.subscription)
		plan = session.subscription_metadata&.plan || "pro"

		user.create_subscription!(
			stripe_customer_id: session.customer,
			stripe_subscription_id: session.subscription,
			status: subscription_data.status,
			plan: plan,
			current_period_end: Time.at(subscription_data.current_period_end)
		)
	end

	def handle_subscription_updated(subscription)
		user_subscription = Subscription.find_by(stripe_subscription_id: subscription.id)
		return unless user_subscription

		user_subscription.update(
			status: subscription.status,
			current_period_end: Time.at(subscription.current_period_end)
		)
	end

	def handle_subscription_deleted(subscription)
		user_subscription = Subscription.find_by(stripe_subscription_id: subscription.id)
		return unless user_subscription

		user_subscription.update(status: "canceled")
	end

	def handle_payment_succeeded(invoice)

		Rails.logger.info "Payment succeeded for invoice: #{invoice.id}"
	end

	def handle_payment_failed(invoice)
		Rails.logger.warn "Payment failed for invoice: #{invoice.id}"
	end
end