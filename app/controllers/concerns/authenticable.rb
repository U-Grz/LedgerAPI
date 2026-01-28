module Authenticable
  extend ActiveSupport::Concern
  
  included do
    # Run authenticate_user! before every action in the controller
    before_action :authenticate_user!
  end
  
  private
  
  def authenticate_user!
    # Get Authorization header from request
    # Example: "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
    header = request.headers['Authorization']
    
    # Extract token from header
    # Split "Bearer TOKEN" and get the token part
    header = header.split(' ').last if header
    
    begin
      # Decode the JWT token
      @decoded = JsonWebToken.decode(header)
      
      # Find user by ID from token
      @current_user = User.find(@decoded[:user_id])
      
    rescue ActiveRecord::RecordNotFound => e
      # User ID from token doesn't exist in database
      # This can happen if user was deleted but token still valid
      render json: { 
        error: 'Unauthorized',
        message: 'User not found'
      }, status: :unauthorized
      
    rescue JWT::DecodeError => e
      # Token is invalid, expired, or malformed
      render json: { 
        error: 'Unauthorized',
        message: 'Invalid or expired token'
      }, status: :unauthorized
    end
  end
  
  def current_user
    @current_user
  end
end
