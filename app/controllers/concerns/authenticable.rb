# app/controllers/concerns/authenticable.rb
module Authenticable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    # Check if this is an API request (has Authorization header)
    if request.headers['Authorization'].present?
      authenticate_api_user!
    else
      authenticate_web_user!
    end
  end

  # API Authentication (JWT)
  def authenticate_api_user!
    header = request.headers['Authorization']
    token = header.split(' ').last if header
    
    decoded = JsonWebToken.decode(token)
    
    if decoded
      @current_user = User.find_by(id: decoded[:user_id])
      render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  # Web Authentication (Session)
  def authenticate_web_user!
    @current_user = User.find_by(id: session[:user_id])
    
    unless @current_user
      redirect_to login_path, alert: "Please log in to continue"
    end
  end

  def current_user
    @current_user
  end
end