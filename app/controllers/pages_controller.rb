class PagesController < ApplicationController
  
  def home
    # If user is already logged in, send them to dashboard
    if session[:user_id] && User.find_by(id: session[:user_id])
      redirect_to dashboard_path
    end
    # Otherwise, show home page
  end
end