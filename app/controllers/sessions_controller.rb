# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  # No authentication needed for login pages
  
  # GET /login - Shows login form
  def new
    # Redirect if already logged in
    if session[:user_id] && User.find_by(id: session[:user_id])
      redirect_to dashboard_path, notice: "You're already logged in"
    end
  end
  
  # POST /login - Process login
  def create
    user = User.find_by(email: params[:email])
    
    if user&.authenticate(params[:password])
      # Store user ID in session
      session[:user_id] = user.id
      
      # Redirect to dashboard
      redirect_to dashboard_path, notice: "Welcome back, #{user.name}!"
    else
      # Login failed
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end
  
  # DELETE /logout - Logout user
  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "You have been logged out"
  end
end