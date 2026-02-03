class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:password])

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: "Welcome back, #{user.name}!"
    else
      flash.now[:alert] = "Invallid email or password"
      render :new, status: :unprocessable_entity
    end 
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "You have been logged out"
  end
end
