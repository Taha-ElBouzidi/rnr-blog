module ApplicationHelper
  # Flash message CSS classes
  def flash_class(type)
    case type.to_s
    when 'notice' then 'alert-success'
    when 'alert' then 'alert-error'
    else 'alert-info'
    end
  end

  # Status badge helper
  def status_badge(published_at)
    if published_at
      content_tag :span, 'Published', class: 'badge badge-success'
    else
      content_tag :span, 'Draft', class: 'badge badge-warning'
    end
  end

  # Avatar initials helper
  def avatar_initials(user, size: 'md')
    initial = user&.name&.first&.upcase || '?'
    content_tag :div, initial, class: "avatar avatar-#{size} avatar-primary"
  end

  # Comments count helper
  def comments_count_text(count)
    "#{count} #{count == 1 ? 'comment' : 'comments'}"
  end
end
