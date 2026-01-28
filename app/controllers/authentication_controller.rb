class AuthenticationController < ApplicationController
  
  def signup
    # Create new user with provided parameters
    user = User.new(user_params)
    
    # Try to save user to database
    if user.save
      token = JsonWebToken.encode(user_id: user.id)
      
      # Return success response with token and user info
      render json: {
        message: 'User created successfully',
        token: token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name
        }
      }, status: :created  # 201 Created
      
    else
      render json: { 
        errors: user.errors.full_messages 
      }, status: :unprocessable_entity  # 422 Unprocessable Entity
    end
  end
  
  def login
    # Find user by email
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      # Success! Generate JWT token
      token = JsonWebToken.encode(user_id: user.id)
      
      render json: {
        message: 'Login successful',
        token: token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          balance: user.balance  # Current balance
        }
      }
      
    else
      render json: { 
        error: 'Invalid email or password' 
      }, status: :unauthorized  # 401 Unauthorized
    end
  end
  
  private
  
  def user_params
    params.permit(:email, :password, :password_confirmation, :name)
  end
end
