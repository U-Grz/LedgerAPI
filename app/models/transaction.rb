class Transaction < ApplicationRecord
  belongs_to :user
  
  validates :amount, 
    presence: true,                    # Can't be blank
    numericality: { greater_than: 0 }  # Must be positive number
  
  validates :transaction_type, 
    presence: true,                    # Can't be blank
    inclusion: { 
      in: %w[income expense],          # Only these two values allowed
      message: "%{value} is not a valid type. Use 'income' or 'expense'"
    }
  
  validates :description, presence: true
  
  validates :date, presence: true
  
  default_scope { order(date: :desc, created_at: :desc) }
  
  scope :income, -> { where(transaction_type: 'income') }
  
  scope :expense, -> { where(transaction_type: 'expense') }
  
  scope :by_date_range, ->(start_date, end_date) { 
    where(date: start_date..end_date) 
  }
  
  scope :by_type, ->(type) { 
    where(transaction_type: type) if type.present? 
  }
  
  scope :search, ->(query) { 
    where('description ILIKE ?', "%#{query}%") if query.present? 
  }
  
  before_save :normalize_transaction_type
  
  private
  
  def normalize_transaction_type
    self.transaction_type = transaction_type.downcase
  end
end