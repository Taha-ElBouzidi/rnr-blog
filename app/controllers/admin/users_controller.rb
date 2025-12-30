module Admin
  class UsersController < BaseController
    def index
      @users = User.order(created_at: :desc)
      
      if params[:role].present?
        @users = @users.where(role: params[:role])
      end
      
      if params[:search].present?
        @users = @users.where("name LIKE ? OR email LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
      end
    end

    def update
      @user = User.find(params[:id])
      
      if @user == current_user
        redirect_to admin_users_path, alert: "❌ You cannot change your own role."
        return
      end
      
      if @user.update(user_params)
        redirect_to admin_users_path, notice: "✅ User updated successfully."
      else
        redirect_to admin_users_path, alert: "❌ Failed to update user: #{@user.errors.full_messages.join(', ')}"
      end
    end

    def destroy
      @user = User.find(params[:id])
      
      if @user == current_user
        redirect_to admin_users_path, alert: "❌ You cannot delete yourself."
        return
      end
      
      if @user.posts.any? || @user.comments.any?
        redirect_to admin_users_path, alert: "❌ Cannot delete user with existing posts or comments."
        return
      end
      
      @user.destroy
      redirect_to admin_users_path, notice: "✅ User deleted successfully."
    end

    private

    def user_params
      params.require(:user).permit(:role)
    end
  end
end
