class Subscription < ApplicationRecord
  belongs_to :user

  validates :stripe_customer_id, presence: true
  validates :stripe_subscription_id, presence: true
  validates :status, presence: true
  validates :plan, presence: true, inclusion: { in: %w[pro business] }

  def active?
    status == "active" || status == "trialing"
  end

  def canceled?
    status == "canceled"
  end

  def past_due?
    status == "past_due"
  end
end
