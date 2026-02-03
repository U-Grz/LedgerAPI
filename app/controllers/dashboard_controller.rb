class DashboardController < ApplicationController
  def index
    @recent_transactions = current_user.transactions.recent.limit(10)

    @total_income = current_user.transactions.income.sum(:amount)
    @total_expenses = current_user.transactions.expense.sum(:amount)
    @balance = @total_income - @total_expenses

    @this_month_income = current_user.transactions.income.where("date >= ?", date.today.beginning_of_month).sum(:amount)
    @this_month_expenses = current_user.transactions.expense.where("date >= ?", date.today.beginning_of_month).sum(:amount)
  end
end
