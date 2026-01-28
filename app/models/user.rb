class User < ApplicationRecord
  has_secure_password
  
  has_many :transactions, dependent: :destroy
  
  validates :email, 
    presence: true,                           # Can't be blank
    uniqueness: true,                         # No duplicate emails
    format: { with: URI::MailTo::EMAIL_REGEXP }  # Must be valid email
  
  validates :name, presence: true
  
  validates :password, 
    length: { minimum: 6 },                   # At least 6 characters
    if: -> { new_record? || !password.nil? }  # Only on create or update
  
  
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