class CommentPolicy < ApplicationPolicy
  def create?
    logged_in? # Must be logged in to create comments
  end

  def destroy?
    logged_in? && (owner? || admin?)
  end
end
