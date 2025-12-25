module Authorizable
  extend ActiveSupport::Concern

  included do
    helper_method :can_edit_post?, :can_delete_comment?
  end

  private

  def require_login
    unless current_user
      redirect_to login_path, alert: "You must be logged in to perform this action."
    end
  end

  def can_edit_post?(post)
    current_user && (current_user.id == post.user_id || current_user.role == "admin")
  end

  def can_delete_comment?(comment)
    current_user && (current_user.id == comment.user_id || current_user.role == "admin")
  end
end
