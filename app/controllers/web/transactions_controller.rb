class Web::TransactionsController < ApplicationController
  before_action :authenticate_web_user!
  before_action :set_transaction, only: [:edit, :update, :destroy]
  
  def index
    @transactions = current_user.transactions # Already ordered by default_scope
    @transaction = Transaction.new # Fixed: was @transactions
  end
  
  def new
    @transaction = current_user.transactions.build
  end
  
  def create
    @transaction = current_user.transactions.build(transaction_params)
    
    if @transaction.save
      respond_to do |format|
        format.html { redirect_to transactions_path, notice: "Transaction created!" }
        format.turbo_stream
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
        format.html { redirect_to transactions_path, notice: "Transaction updated!" }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @transaction.destroy
    respond_to do |format|
      format.html { redirect_to transactions_path, notice: "Transaction deleted!" }
      format.turbo_stream
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
  
  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to transactions_path, alert: "Transaction not found"
  end
  
  def transaction_params
    params.require(:transaction).permit(:amount, :description, :category, :transaction_type, :date)
  end
end