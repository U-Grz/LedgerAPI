class SubscriptionsController < ApplicationController
	before_action :autheticate_web_user!

	def new
		if current_user.subscribed?
			redirect_to subscription_path, notice: "You already have an active subscription"
			return
		end

		@plans = {
			pro:{
				name: "Pro",
				price: 4.99,
				price_id: "price_1SxQp01ZlBmkpq2TvRRXQBv8",
				features: [
					"Unlimited transactions",
					"Advanced analytics & charts",
					"CSV/Excel eport",
					"Email support",
					"Custom categories"
				]
			},
			business:{
				name: "Business",
				price: 15.00,
				price_id: "price_1SxQtZ1ZlBmkpq2TQFHCfx2G",
				features: [
					"Everything in Pro",
          			"Multi-user access (up to 5)",
          			"Team collaboration",
          			"Priority support",
          			"API access",
          			"Custom branding"
          		]
			}
		}
	end

	def create
		begin
			if current_user.subscription&.stripe_customer_id
				customer_id = current_user.subscription.stripe_customer_id
			else
				customer = Stripe::Customer.create(
					email: current_user.email,
					name: current_user.name,
					metadata: { user_id: current_user.id }
				)
				customer_id = customer.id
			end

			session = Stripe::Checkout::Session.create(
				customer: customer_id,
				mode: "subscription",
				line_items: [{
					price: params[:price_id],
					quantity: 1
				}],
				success_url: subscription_success_url,
				cancel_url: new_subscription_url,
				subscription_data: {
					metadata:{
						user_id: current_user.id,
						plan: params[:plan]
					}
				}
			)

			redirect_to session.url, allow_other_host: true	
		rescue Stripe::StripeError => e
			redirect_to new_subscription_path, alert: "Payment error: #{e.message}"
		end
	end

	def show
		@subscription = current_user.subscription

		unless @subscription
			redirect_to new_subscription_path, alert: "You don't have an active subscription"
		end
	end

	def success

	end

	def cancel
		subscription = current_user.subscription

		if subscription&.stripe_subscription_id
			begin
				Stripe::Subscription.delete(subscription.stripe_subscription_id)
				redirect_to dashboard_path, notice: "Subscription cancelled successfully"
			rescue
				redirect_to subscription_path, alert: "No active subscription found"
			end
		else
			redirect_to dashboard_path, alert: "No active subscription found"
		end
	end

	private

	def authenticate_web_user!
		@current_user = User.find_by(id: session[:user_id])

		unless @current_user
			redirect_to login_path, alert: "Please log in to continue"
		end
	end

	def current_user
		@current_user
	end

	helper_method :current_user
end 