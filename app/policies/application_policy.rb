# Base class for application policies
class ApplicationPolicy < ActionPolicy::Base
  # Configure additional authorization contexts here
  authorize :user, allow_nil: true

  # Read more about authorization context: https://actionpolicy.evilmartians.io/#/authorization_context

  private

  # Define shared methods useful for most policies.
  def owner?
    return false unless user && record.respond_to?(:user_id)
    record.user_id == user.id
  end

  def admin?
    user&.role == "admin"
  end

  def logged_in?
    user.present?
  end
end
