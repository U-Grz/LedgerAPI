class WebhooksController < ApplicationController
	skip_before_action :verify_authenticity_token
	
	def stripe
		Rails.logger.info "=" * 80
		Rails.logger.info "🔔 WEBHOOK RECEIVED AT #{Time.current}"
		
		payload = request.body.read
		sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
		endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)
		
		begin
			event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
			Rails.logger.info "✅ Event type: #{event.type}"
		rescue JSON::ParserError => e
			Rails.logger.error "❌ JSON Parser Error: #{e.message}"
			render json: { error: "Invalid payload" }, status: 400
			return
		rescue Stripe::SignatureVerificationError => e
			Rails.logger.error "❌ Signature Verification Error: #{e.message}"
			render json: { error: "Invalid signature" }, status: 400
			return
		end
		
		# Handle the event
		case event.type
		when "checkout.session.completed"
			handle_checkout_session_completed(event.data.object)
		when "customer.subscription.updated"
			handle_subscription_updated(event.data.object)
		when "customer.subscription.deleted"
			handle_subscription_deleted(event.data.object)
		when "invoice.payment_succeeded", "invoice.paid"
			handle_invoice_paid(event.data.object)
		when "invoice.payment_failed"
			Rails.logger.warn "⚠️ Payment failed"
		else
			Rails.logger.info "ℹ️ Unhandled event: #{event.type}"
		end
		
		Rails.logger.info "=" * 80
		render json: { message: "success" }
	end
	
	private
	
	def handle_checkout_session_completed(session)
		Rails.logger.info "🎉 Processing checkout.session.completed"
		
		user_id = session.metadata&.[]("user_id")
		unless user_id
			Rails.logger.error "❌ No user_id in metadata"
			return
		end
		
		user = User.find_by(id: user_id)
		unless user
			Rails.logger.error "❌ User not found: #{user_id}"
			return
		end
		
		if user.subscription.present?
			Rails.logger.info "ℹ️ Subscription already exists"
			return
		end
		
		create_subscription_from_stripe(user, session.customer, session.subscription, session.metadata&.[]("plan"))
	end
	
	def handle_invoice_paid(invoice)
		Rails.logger.info "💰 Processing invoice.paid for invoice: #{invoice.id}"
		
		# Get user_id from invoice line items metadata
		line_item = invoice.lines.data.first
		unless line_item
			Rails.logger.error "❌ No line items in invoice"
			return
		end
		
		user_id = line_item.metadata&.[]("user_id")
		plan = line_item.metadata&.[]("plan")
		
		Rails.logger.info "   User ID: #{user_id}, Plan: #{plan}"
		
		unless user_id && plan
			Rails.logger.error "❌ No user_id or plan in metadata"
			return
		end
		
		user = User.find_by(id: user_id)
		unless user
			Rails.logger.error "❌ User not found: #{user_id}"
			return
		end
		
		if user.subscription.present?
			Rails.logger.info "ℹ️ Subscription already exists for user #{user.id}"
			return
		end
		
		# FIX: Access subscription ID from the correct location in the webhook payload
		# The subscription ID is in the line item's parent structure
		subscription_id = line_item.dig('parent', 'subscription_item_details', 'subscription')
		
		# Fallback: Also check the invoice's subscription field (for older API versions)
		subscription_id ||= invoice['subscription']
		
		unless subscription_id
			Rails.logger.error "❌ No subscription ID in invoice"
			Rails.logger.error "   Invoice data: #{invoice.to_h.slice('id', 'subscription', 'parent')}"
			return
		end
		
		Rails.logger.info "   Subscription ID: #{subscription_id}"
		create_subscription_from_stripe(user, invoice.customer, subscription_id, plan)
	end
	
	def create_subscription_from_stripe(user, customer_id, subscription_id, plan)
		Rails.logger.info "🔨 Creating subscription for user #{user.id}"
		
		begin
			stripe_subscription = Stripe::Subscription.retrieve(subscription_id)
			Rails.logger.info "   Stripe subscription status: #{stripe_subscription.status}"
			
			db_subscription = user.create_subscription!(
				stripe_customer_id: customer_id,
				stripe_subscription_id: subscription_id,
				status: stripe_subscription.status,
				plan: plan || "pro",
				current_period_end: Time.at(stripe_subscription.current_period_end)
			)
			
			Rails.logger.info "✅ ✅ ✅ SUBSCRIPTION CREATED! ID: #{db_subscription.id}"
		rescue => e
			Rails.logger.error "❌ Error creating subscription: #{e.class} - #{e.message}"
			Rails.logger.error e.backtrace.first(5).join("\n")
		end
	end
	
	def handle_subscription_updated(subscription)
		Rails.logger.info "🔄 Updating subscription: #{subscription.id}"
		
		user_subscription = Subscription.find_by(stripe_subscription_id: subscription.id)
		unless user_subscription
			Rails.logger.warn "⚠️ Subscription not found: #{subscription.id}"
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
			Rails.logger.warn "⚠️ Subscription not found: #{subscription.id}"
			return
		end
		
		user_subscription.update(status: "canceled")
		Rails.logger.info "✅ Subscription canceled"
	end
end