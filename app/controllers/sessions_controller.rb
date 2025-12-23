class SessionsController < ApplicationController
  def new
    @users = User.all
  end

  def create
    user = User.find_by(id: params[:user_id])
    if user
      session[:user_id] = user.id
      redirect_to root_path, notice: "Logged in as #{user.name}!"
    else
      redirect_to login_path, alert: "Please select a user."
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Logged out successfully."
  end
end
