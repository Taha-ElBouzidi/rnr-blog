module Authorizable
  extend ActiveSupport::Concern

  # This module is now deprecated in favor of ActionPolicy
  # Keeping it for backward compatibility, but ActionPolicy handles authorization now
  
  included do
    # ActionPolicy provides allowed_to? helper method in controllers and views
  end
end
