class PagesController < ApplicationController
  def home
    # If user is already logged in, send them to dashboard
    if session[:user_id] && User.find_by(id: session[:user_id])
      redirect_to dashboard_path
    end
    # Otherwise, show home page
  end
  
  private
  
  # Make current_user available in views
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
  
  helper_method :current_user
end