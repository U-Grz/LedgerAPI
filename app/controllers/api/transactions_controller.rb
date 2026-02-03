class Api::TransactionsController < ApplicationController  # Include authentication - all actions require valid JWT token
  include Authenticable
  
  # Run set_transaction before these specific actions
  before_action :set_transaction, only: [:show, :update, :destroy]
  
  def index
    # Start with current user's transactions
    # current_user comes from Authenticable concern
    @transactions = current_user.transactions
    
    # Apply filters if provided
    # by_type scope: filters by 'income' or 'expense'
    @transactions = @transactions.by_type(params[:type]) if params[:type].present?
    
    # search scope: searches in description field
    @transactions = @transactions.search(params[:search]) if params[:search].present?
    
    # Date range filter
    if params[:start_date].present? && params[:end_date].present?
      @transactions = @transactions.by_date_range(params[:start_date], params[:end_date])
    end
    
    # Pagination using Kaminari gem
    # Default: page 1, 20 items per page
    page = params[:page] || 1
    per_page = params[:per_page] || 20
    @transactions = @transactions.page(page).per(per_page)
    
    # Return JSON response
    render json: {
      transactions: @transactions.as_json(
        only: [:id, :amount, :transaction_type, :description, :date, :created_at]
      ),
      pagination: {
        current_page: @transactions.current_page,
        total_pages: @transactions.total_pages,
        total_count: @transactions.total_count
      }
    }
  end
  
  def show
    render json: @transaction
  end
  
  def create
    # Build new transaction for current user
    # This automatically sets user_id
    @transaction = current_user.transactions.build(transaction_params)
    
    # Try to save
    if @transaction.save
      render json: {
        message: 'Transaction created successfully',
        transaction: @transaction,
        balance: current_user.balance  # Recalculated balance
      }, status: :created  # 201 Created
      
    else
      render json: { 
        errors: @transaction.errors.full_messages 
      }, status: :unprocessable_entity  # 422 Unprocessable Entity
    end
  end
  
  def update
    # Try to update with new parameters
    if @transaction.update(transaction_params)
      render json: {
        message: 'Transaction updated successfully',
        transaction: @transaction,
        balance: current_user.balance  # Recalculated balance
      }
      
    else
      render json: { 
        errors: @transaction.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    # Delete the transaction
    @transaction.destroy
    
    # Return success message and updated balance
    render json: {
      message: 'Transaction deleted successfully',
      balance: current_user.balance  # Recalculated balance
    }
  end
  
  def summary
    # Default date range: first transaction to today
    start_date = params[:start_date] || current_user.transactions.minimum(:date)
    end_date = params[:end_date] || Date.today
    
    # Get transactions in date range
    transactions = current_user.transactions.by_date_range(start_date, end_date)
    
    # Calculate totals
    total_income = transactions.income.sum(:amount)
    total_expenses = transactions.expense.sum(:amount)
    net_balance = total_income - total_expenses
    
    # Return summary
    render json: {
      period: {
        start_date: start_date,
        end_date: end_date
      },
      summary: {
        total_income: total_income,
        total_expenses: total_expenses,
        net_balance: net_balance,
        transaction_count: transactions.count,
        income_count: transactions.income.count,
        expense_count: transactions.expense.count
      },
      current_balance: current_user.balance  # Overall balance (all time)
    }
  end
  
  def balance
    # If date provided, get historical balance
    # Otherwise, get current balance
    date = params[:date] ? Date.parse(params[:date]) : Date.today
    
    render json: {
      balance: current_user.balance_as_of(date),
      as_of_date: date,
      total_income: current_user.transactions.income.where('date <= ?', date).sum(:amount),
      total_expenses: current_user.transactions.expense.where('date <= ?', date).sum(:amount)
    }
  end
  
  private
  
  def set_transaction
    # Find transaction in current_user's transactions only
    # This prevents users from accessing other users' transactions
    @transaction = current_user.transactions.find(params[:id])
    
  rescue ActiveRecord::RecordNotFound
    # Transaction not found or doesn't belong to current user
    render json: { 
      error: 'Transaction not found' 
    }, status: :not_found  # 404 Not Found
  end
  
  def transaction_params
    params.require(:transaction).permit(
      :amount, 
      :transaction_type, 
      :description, 
      :date
    )
  end
end
