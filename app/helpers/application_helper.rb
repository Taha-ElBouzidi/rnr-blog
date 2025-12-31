module ApplicationHelper
  # ActionPolicy helper - check if user can perform action on record
  def can?(action, record)
    allowed_to?(action, record)
  rescue ActionPolicy::Unauthorized
    false
  end

  # Flash message CSS classes
  def flash_class(type)
    case type.to_s
    when "notice", "success" then "alert-success"
    when "alert", "error" then "alert-error"
    when "warning" then "alert-warning"
    when "info" then "alert-info"
    else "alert-info"
    end
  end

  # Status badge helper
  def status_badge(published_at)
    if published_at
      content_tag :span, "Published", class: "badge badge-success"
    else
      content_tag :span, "Draft", class: "badge badge-warning"
    end
  end

  # Avatar initials helper
  def avatar_initials(user, size: "md")
    if user&.avatar&.attached?
      image_tag user.avatar.variant(resize_to_limit: [ 100, 100 ]),
                alt: user.name,
                class: "avatar avatar-#{size} rounded-full object-cover"
    else
      initial = user&.name&.first&.upcase || "?"
      content_tag :div, initial, class: "avatar avatar-#{size} avatar-primary"
    end
  end

  # Comments count helper
  def comments_count_text(count)
    "#{count} #{count == 1 ? 'comment' : 'comments'}"
  end
end
