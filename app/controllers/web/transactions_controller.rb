class Web::TransactionsController < ApplicationController
  before_action :set_transaction, only: [:edit, :update, :destroy]
  def index
    @transactions = current_user.transactions.recent
    @transactions = Transaction.new
  end

  def new
    @transaction = current_user.transactions.build
  end

  def create
    @transaction = current_user.transactions.build(transaction_params)
    
    if @transaction.save
      respond_to do |format|
        format.html { redirect_to transactions_path, notice: "Transaction created!" }
        format.turbo_stream # For real-time updates
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @transaction.update(transaction_params)
      respond_to do |format|
        format.html { redirect_to transactions_path, notice: "Transaction updated" }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy
    respond_to do |format|
      format.html { redirect_to transactions_path, notice: "Transaction Deleted" }
    end
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(:amount, :description, :category, :transaction_type, :date)
  end
end
