class User < ApplicationRecord
  has_secure_password
  has_one :subscription, dependent: :destroy
  has_many :transactions, dependent: :destroy
  
  validates :email, 
    presence: true,                           # Can't be blank
    uniqueness: true,                         # No duplicate emails
    format: { with: URI::MailTo::EMAIL_REGEXP }  # Must be valid email
  
  validates :name, presence: true
  
  validates :password, 
    length: { minimum: 6 },                   # At least 6 characters
    if: -> { new_record? || !password.nil? }  # Only on create or update
  
  def subscribed?
  	subscription&.active?
  end

  def free_tier?
  	!subscribed?
  end

  def pro?
  	subscription&.active? && subscription.plan == "pro"
  end

  def business?
  	subscription&.active? && subscription.plan == "business"
  end

  def can_export?
  	pro? || business?
  end

  def transaction_limit
  	return Float::INFINITY if subscribed?
  	50
  end

  def within_transaction_limit?
  	transactions.count < transaction_limit
  end
  
  def balance
    income = transactions.income.sum(:amount)
    
    expenses = transactions.expense.sum(:amount)
    
    income - expenses
  end
  
  def balance_as_of(date)
    income = transactions.income.where('date <= ?', date).sum(:amount)
    
    expenses = transactions.expense.where('date <= ?', date).sum(:amount)
    
    income - expenses
  end
end