class DashboardController < ApplicationController
  before_action :authenticate_web_user!
  
  def index
    @recent_transactions = current_user.transactions.recent.limit(10)
    
    # Calculate stats
    @total_income = current_user.transactions.income.sum(:amount)
    @total_expenses = current_user.transactions.expense.sum(:amount)
    @balance = @total_income - @total_expenses
    
    # This month stats
    @this_month_income = current_user.transactions
                                      .income
                                      .where('date >= ?', Date.today.beginning_of_month)
                                      .sum(:amount)
    
    @this_month_expenses = current_user.transactions
                                        .expense
                                        .where('date >= ?', Date.today.beginning_of_month)
                                        .sum(:amount)
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