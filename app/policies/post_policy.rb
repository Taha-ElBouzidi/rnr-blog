class PostPolicy < ApplicationPolicy
  # Scope for filtering posts based on user permissions
  relation_scope do |relation|
    # Admins can see all posts (including drafts)
    # Members can only see published posts or their own posts
    if user&.role == "admin"
      relation
    elsif user
      relation.where("published_at IS NOT NULL OR user_id = ?", user.id)
    else
      relation.published
    end
  end

  def index?
    true # Anyone can view the posts index
  end

  def show?
    # Rule: Anyone can see published posts
    # Owner and admin can see unpublished posts
    return false unless record
    record.published? || (logged_in? && (owner? || admin?))
  end

  def create?
    logged_in? # Must be logged in to create posts
  end

  def new?
    create?
  end

  def update?
    # Rule: Only owner or admin can edit
    logged_in? && (owner? || admin?)
  end

  def edit?
    update?
  end

  def destroy?
    # Rule: Owner or admin can delete
    logged_in? && (owner? || admin?)
  end

  def publish?
    # Only owner or admin can publish
    logged_in? && (owner? || admin?)
  end

  def unpublish?
    # Only owner or admin can unpublish
    logged_in? && (owner? || admin?)
  end

  private

  def manage?
    logged_in? && (owner? || admin?)
  end
end
