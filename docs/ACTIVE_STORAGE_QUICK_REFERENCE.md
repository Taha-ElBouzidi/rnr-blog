# Active Storage Quick Reference

## Upload Image Files

### User Avatar (Registration)
```erb
<!-- app/views/devise/registrations/new.html.erb -->
<%= f.file_field :avatar, accept: "image/*" %>
```

### User Avatar (Edit Profile)
```erb
<!-- app/views/devise/registrations/edit.html.erb -->
<%= f.file_field :avatar, accept: "image/*" %>
```

### Post Featured Image
```erb
<!-- app/views/posts/_form.html.erb -->
<%= form.file_field :featured_image, accept: "image/*" %>
```

## Display Images

### Avatar in Views
```erb
<!-- Shows image if attached, otherwise shows initials -->
<%= avatar_initials(user) %>
```

### Check if Image Attached
```erb
<% if user.avatar.attached? %>
  <%= image_tag user.avatar %>
<% end %>
```

### Featured Image with Variant
```erb
<% if post.featured_image.attached? %>
  <%= image_tag post.featured_image.variant(resize_to_limit: [800, 600]) %>
<% end %>
```

## Common Variants

```ruby
# Thumbnail
image.variant(resize_to_limit: [100, 100])

# Medium
image.variant(resize_to_limit: [400, 300])

# Large
image.variant(resize_to_limit: [800, 600])

# Specific dimensions (crop)
image.variant(resize_to_fill: [300, 300])
```

## In Controllers

### Permit Parameters
```ruby
# ApplicationController (Devise)
devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :avatar])

# PostsController
params.require(:post).permit(:title, :body, :featured_image)
```

## In Models

### Attach Image
```ruby
has_one_attached :avatar
has_one_attached :featured_image
```

### Validation
```ruby
validate :avatar_format

def avatar_format
  return unless avatar.attached?
  
  unless avatar.content_type.in?(%w[image/jpeg image/png])
    errors.add(:avatar, 'must be JPEG or PNG')
  end
  
  if avatar.byte_size > 5.megabytes
    errors.add(:avatar, 'must be less than 5MB')
  end
end
```

## Console Commands

```ruby
# Attach file
user = User.first
user.avatar.attach(
  io: File.open('/path/to/image.jpg'),
  filename: 'avatar.jpg',
  content_type: 'image/jpeg'
)

# Check if attached
user.avatar.attached?  # => true/false

# Get URL
url_for(user.avatar)

# Delete
user.avatar.purge

# Get metadata
user.avatar.filename    # => "avatar.jpg"
user.avatar.byte_size   # => 12345
user.avatar.content_type # => "image/jpeg"
```

## Performance

### Eager Load Attachments
```ruby
# Avoid N+1 queries
User.with_attached_avatar.all
Post.with_attached_featured_image.recent
```

### Direct Upload (Future Enhancement)
```erb
<%= f.file_field :avatar, direct_upload: true %>
```

## Troubleshooting

### Image not displaying?
```bash
# Check file exists
ls storage/

# Check permissions
chmod -R 755 storage/

# Check image_processing installed
bundle list | grep image_processing

# Check vips installed (macOS)
brew install vips
```

### Validation not working?
```ruby
# In console, check errors
user.save
user.errors.full_messages
```

## Supported Formats

**User Avatars**: JPEG, JPG, PNG, GIF (max 5MB)  
**Post Images**: JPEG, JPG, PNG, GIF, WebP (max 10MB)
