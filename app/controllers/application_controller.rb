class ApplicationController < ActionController::Base
  include ActionPolicy::Controller
  
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Devise provides current_user helper automatically
  
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  # ActionPolicy: Set authorization context
  def authorization_context
    { user: current_user }
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  # Redirect to posts page after sign in
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || posts_path
  end

  # Redirect to posts page after sign up
  def after_sign_up_path_for(resource)
    posts_path
  end

  # Redirect to posts page after sign out
  def after_sign_out_path_for(resource_or_scope)
    posts_path
  end
  
  # Store location before redirecting to login
  def store_user_location!
    store_location_for(:user, request.fullpath) if request.get? && !devise_controller?
  end
end
