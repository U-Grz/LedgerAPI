class WebhooksController < ApplicationController
	skip_before_action :verify_authenticity_token
	
	def stripe
		Rails.logger.info "=" * 80
		Rails.logger.info "🔔 WEBHOOK RECEIVED AT #{Time.current}"
		Rails.logger.info "=" * 80
		
		payload = request.body.read
		sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
		endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)
		
		Rails.logger.info "📝 Webhook secret present: #{endpoint_secret.present?}"
		Rails.logger.info "📝 Signature header present: #{sig_header.present?}"
		
		begin
			event = Stripe::Webhook.construct_event(
				payload, sig_header, endpoint_secret
			)
			Rails.logger.info "✅ Webhook signature verified successfully"
			Rails.logger.info "📦 Event type: #{event.type}"
			Rails.logger.info "📦 Event ID: #{event.id}"
		rescue JSON::ParserError => e
			Rails.logger.error "❌ JSON Parser Error: #{e.message}"
			render json: { error: "Invalid payload" }, status: 400
			return
		rescue Stripe::SignatureVerificationError => e
			Rails.logger.error "❌ Signature Verification Error: #{e.message}"
			render json: { error: "Invalid signature" }, status: 400
			return
		end
		
		case event.type
		when "checkout.session.completed"
			Rails.logger.info "🎉 Processing checkout.session.completed"
			handle_checkout_session_completed(event.data.object)
		when "customer.subscription.updated"
			Rails.logger.info "🔄 Processing customer.subscription.updated"
			handle_subscription_updated(event.data.object)
		when "customer.subscription.deleted"
			Rails.logger.info "🗑️ Processing customer.subscription.deleted"
			handle_subscription_deleted(event.data.object)
		when "invoice.payment_succeeded"
			Rails.logger.info "💰 Processing invoice.payment_succeeded"
			handle_payment_succeeded(event.data.object)
		when "invoice.payment_failed"
			Rails.logger.info "⚠️ Processing invoice.payment_failed"
			handle_payment_failed(event.data.object)
		else
			Rails.logger.info "ℹ️ Unhandled event type: #{event.type}"
		end
		
		Rails.logger.info "=" * 80
		render json: { message: "success" }
	end
	
	private
	
	def handle_checkout_session_completed(session)
		Rails.logger.info "🔍 Checkout session details:"
		Rails.logger.info "   Customer: #{session.customer}"
		Rails.logger.info "   Subscription: #{session.subscription}"
		Rails.logger.info "   Metadata: #{session.metadata.to_h}"
		
		user_id = session.metadata&.[]("user_id") || session.client_reference_id
		Rails.logger.info "   User ID from metadata: #{user_id}"
		
		unless user_id
			Rails.logger.error "❌ No user_id found in session metadata or client_reference_id"
			return
		end
		
		user = User.find_by(id: user_id)
		unless user
			Rails.logger.error "❌ User not found with ID: #{user_id}"
			return
		end
		
		Rails.logger.info "✅ Found user: #{user.email} (ID: #{user.id})"
		
		# Check if subscription already exists
		if user.subscription.present?
			Rails.logger.info "ℹ️ Subscription already exists for user #{user.id}"
			return
		end
		
		begin
			subscription_data = Stripe::Subscription.retrieve(session.subscription)
			Rails.logger.info "✅ Retrieved Stripe subscription: #{subscription_data.id}"
			Rails.logger.info "   Status: #{subscription_data.status}"
			
			plan = session.metadata&.[]("plan") || "pro"
			Rails.logger.info "   Plan: #{plan}"
			
			db_subscription = user.create_subscription!(
				stripe_customer_id: session.customer,
				stripe_subscription_id: session.subscription,
				status: subscription_data.status,
				plan: plan,
				current_period_end: Time.at(subscription_data.current_period_end)
			)
			
			Rails.logger.info "✅ ✅ ✅ SUBSCRIPTION CREATED SUCCESSFULLY! ID: #{db_subscription.id}"
		rescue => e
			Rails.logger.error "❌ Error creating subscription: #{e.class} - #{e.message}"
			Rails.logger.error e.backtrace.first(5).join("\n")
		end
	end
	
	def handle_subscription_updated(subscription)
		Rails.logger.info "🔄 Updating subscription: #{subscription.id}"
		user_subscription = Subscription.find_by(stripe_subscription_id: subscription.id)
		
		unless user_subscription
			Rails.logger.warn "⚠️ Subscription not found in database: #{subscription.id}"
			return
		end
		
		user_subscription.update(
			status: subscription.status,
			current_period_end: Time.at(subscription.current_period_end)
		)
		Rails.logger.info "✅ Subscription updated"
	end
	
	def handle_subscription_deleted(subscription)
		Rails.logger.info "🗑️ Deleting subscription: #{subscription.id}"
		user_subscription = Subscription.find_by(stripe_subscription_id: subscription.id)
		
		unless user_subscription
			Rails.logger.warn "⚠️ Subscription not found in database: #{subscription.id}"
			return
		end
		
		user_subscription.update(status: "canceled")
		Rails.logger.info "✅ Subscription marked as canceled"
	end
	
	def handle_payment_succeeded(invoice)
		Rails.logger.info "💰 Payment succeeded for invoice: #{invoice.id}"
		Rails.logger.info "   Subscription ID: #{invoice.subscription}"
		
		# Extract metadata from invoice lines
		line_item = invoice.lines.data.first
		if line_item
			Rails.logger.info "   Line item metadata: #{line_item.metadata.to_h}"
			user_id = line_item.metadata&.[]("user_id")
			plan = line_item.metadata&.[]("plan")
		else
			Rails.logger.warn "⚠️ No line items found in invoice"
			return
		end
		
		unless user_id && plan
			Rails.logger.warn "⚠️ No user_id or plan in metadata"
			return
		end
		
		user = User.find_by(id: user_id)
		unless user
			Rails.logger.error "❌ User not found with ID: #{user_id}"
			return
		end
		
		Rails.logger.info "✅ Found user: #{user.email} (ID: #{user.id})"
		
		# Check if subscription already exists
		if user.subscription.present?
			Rails.logger.info "ℹ️ Subscription already exists for user #{user.id}"
			return
		end
		
		# Create subscription from invoice
		subscription_id = invoice.subscription
		unless subscription_id
			Rails.logger.error "❌ No subscription ID in invoice"
			return
		end
		
		begin
			subscription_data = Stripe::Subscription.retrieve(subscription_id)
			Rails.logger.info "✅ Retrieved Stripe subscription: #{subscription_data.id}"
			
			db_subscription = user.create_subscription!(
				stripe_customer_id: invoice.customer,
				stripe_subscription_id: subscription_id,
				status: subscription_data.status,
				plan: plan,
				current_period_end: Time.at(subscription_data.current_period_end)
			)
			
			Rails.logger.info "✅ ✅ ✅ SUBSCRIPTION CREATED from invoice.payment_succeeded! ID: #{db_subscription.id}"
		rescue => e
			Rails.logger.error "❌ Error creating subscription: #{e.class} - #{e.message}"
			Rails.logger.error e.backtrace.first(5).join("\n")
		end
	end
	
	def handle_payment_failed(invoice)
		Rails.logger.warn "⚠️ Payment failed for invoice: #{invoice.id}"
	end
end