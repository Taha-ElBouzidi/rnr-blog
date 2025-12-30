# Active Storage Implementation Guide

## Overview
Active Storage has been successfully integrated into the RNR Blog application to handle file uploads for:
- **User Avatars** - Profile pictures for user accounts
- **Post Featured Images** - Visual content for blog posts

## What Was Done

### 1. Installation
```bash
bin/rails active_storage:install
bin/rails db:migrate
```

Created three tables:
- `active_storage_blobs` - Stores file metadata
- `active_storage_attachments` - Polymorphic join table linking blobs to models
- `active_storage_variant_records` - Stores image transformation metadata

### 2. Model Attachments

#### User Model (`app/models/user.rb`)
```ruby
has_one_attached :avatar

# Validation
validate :avatar_format

private

def avatar_format
  return unless avatar.attached?
  
  unless avatar.content_type.in?(%w[image/jpeg image/jpg image/png image/gif])
    errors.add(:avatar, 'must be a JPEG, PNG, or GIF image')
  end
  
  if avatar.byte_size > 5.megabytes
    errors.add(:avatar, 'must be less than 5MB')
  end
end
```

**Supported formats:** JPEG, JPG, PNG, GIF  
**Max size:** 5MB

#### Post Model (`app/models/post.rb`)
```ruby
has_one_attached :featured_image

# Validation
validate :featured_image_format

private

def featured_image_format
  return unless featured_image.attached?
  
  unless featured_image.content_type.in?(%w[image/jpeg image/jpg image/png image/gif image/webp])
    errors.add(:featured_image, 'must be a JPEG, PNG, GIF, or WebP image')
  end
  
  if featured_image.byte_size > 10.megabytes
    errors.add(:featured_image, 'must be less than 10MB')
  end
end
```

**Supported formats:** JPEG, JPG, PNG, GIF, WebP  
**Max size:** 10MB

### 3. Controller Permit Parameters

#### ApplicationController
```ruby
def configure_permitted_parameters
  devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :avatar])
  devise_parameter_sanitizer.permit(:account_update, keys: [:name, :avatar])
end
```

#### PostsController
```ruby
def post_params
  params.require(:post).permit(:title, :body, :published_at, :featured_image)
end
```

### 4. View Updates

#### User Registration (`app/views/devise/registrations/new.html.erb`)
```erb
<div class="mb-4">
  <%= f.label :avatar, "Profile Picture (optional)", class: "form-label" %>
  <%= f.file_field :avatar, accept: "image/*", class: "form-input" %>
  <small class="form-hint">JPEG, PNG, or GIF. Max 5MB</small>
</div>
```

#### User Edit (`app/views/devise/registrations/edit.html.erb`)
```erb
<div class="mb-4">
  <%= f.label :avatar, "Profile Picture", class: "form-label" %>
  <% if resource.avatar.attached? %>
    <div class="mb-2">
      <%= image_tag resource.avatar.variant(resize_to_limit: [100, 100]), 
                    class: "rounded-full border-2 border-gray-300" %>
      <p class="text-sm text-gray-600 mt-1">Current avatar (will be replaced if you upload a new one)</p>
    </div>
  <% end %>
  <%= f.file_field :avatar, accept: "image/*", class: "form-input" %>
  <small class="form-hint">JPEG, PNG, or GIF. Max 5MB</small>
</div>
```

#### Post Form (`app/views/posts/_form.html.erb`)
```erb
<div class="mb-4">
  <%= form.label :featured_image, "Featured Image (optional)", class: "form-label" %>
  <%= form.file_field :featured_image, accept: "image/*", class: "form-input" %>
  <small class="form-hint">JPEG, PNG, GIF, or WebP. Max 10MB</small>
  <% if post.featured_image.attached? %>
    <div class="mt-2">
      <%= image_tag post.featured_image.variant(resize_to_limit: [400, 300]), 
                    class: "rounded-md border border-gray-300" %>
      <p class="text-sm text-gray-600 mt-1">Current image (will be replaced if you upload a new one)</p>
    </div>
  <% end %>
</div>
```

#### Post Show View (`app/views/posts/show.html.erb`)
```erb
<% if @post.featured_image.attached? %>
  <div class="mb-4">
    <%= image_tag @post.featured_image.variant(resize_to_limit: [800, 600]), 
                  class: "w-full rounded-lg shadow-md", 
                  alt: @post.title %>
  </div>
<% end %>
```

#### Post Index Card (`app/views/posts/_post.html.erb`)
```erb
<% if post.featured_image.attached? %>
  <%= link_to post_path(post), class: "block mb-3", data: { turbo_frame: "_top" } do %>
    <%= image_tag post.featured_image.variant(resize_to_limit: [400, 300]), 
                  class: "w-full rounded-md object-cover", 
                  alt: post.title,
                  style: "max-height: 200px;" %>
  <% end %>
<% end %>
```

### 5. Helper Method Update

#### ApplicationHelper (`app/helpers/application_helper.rb`)
```ruby
def avatar_initials(user, size: 'md')
  if user&.avatar&.attached?
    image_tag user.avatar.variant(resize_to_limit: [100, 100]), 
              alt: user.name, 
              class: "avatar avatar-#{size} rounded-full object-cover"
  else
    initial = user&.name&.first&.upcase || '?'
    content_tag :div, initial, class: "avatar avatar-#{size} avatar-primary"
  end
end
```

## Storage Configuration

### Development & Production
```yaml
# config/storage.yml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>
```

Files stored at: `storage/` directory

### Test Environment
```yaml
test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>
```

## Image Variants

Active Storage uses the `image_processing` gem (via libvips) to create image variants on-the-fly:

```ruby
# Avatar thumbnail
user.avatar.variant(resize_to_limit: [100, 100])

# Post thumbnail
post.featured_image.variant(resize_to_limit: [400, 300])

# Post full size
post.featured_image.variant(resize_to_limit: [800, 600])
```

Variants are cached and only generated once.

## Usage Examples

### Creating a Post with Featured Image
```ruby
# In Rails console
user = User.first
post = Post.new(
  title: "My Post with Image",
  body: "This post has a beautiful image",
  user: user
)
post.featured_image.attach(
  io: File.open('path/to/image.jpg'),
  filename: 'image.jpg',
  content_type: 'image/jpeg'
)
post.save
```

### Updating User Avatar
```ruby
# In Rails console
user = User.first
user.avatar.attach(
  io: File.open('path/to/avatar.png'),
  filename: 'avatar.png',
  content_type: 'image/png'
)
```

### Checking if Attachment Exists
```erb
<% if post.featured_image.attached? %>
  <%= image_tag post.featured_image %>
<% end %>
```

### Deleting Attachments
```ruby
# Remove avatar
user.avatar.purge

# Remove featured image
post.featured_image.purge
```

## Authorization

Attachments follow the same authorization rules as their parent models:
- **User avatars**: Only the user can upload/change their own avatar
- **Post featured images**: Only post owner or admin can upload/change featured images (via PostPolicy)

## Performance Considerations

1. **Lazy Loading**: Variants are generated on first request and cached
2. **N+1 Queries**: Use `with_attached_avatar` or `with_attached_featured_image` to eager load:
   ```ruby
   User.with_attached_avatar.all
   Post.with_attached_featured_image.recent
   ```

3. **File Storage**: In production, consider migrating to cloud storage (S3, GCS, Azure) for better scalability

## Migration to Cloud Storage (Optional)

To use Amazon S3 in production:

1. Add to Gemfile:
   ```ruby
   gem "aws-sdk-s3", require: false
   ```

2. Configure `config/storage.yml`:
   ```yaml
   amazon:
     service: S3
     access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
     secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
     region: us-east-1
     bucket: your_bucket_name
   ```

3. Update `config/environments/production.rb`:
   ```ruby
   config.active_storage.service = :amazon
   ```

## File Structure
```
storage/
├── 6d/                    # Organized by first 2 chars of blob key
│   └── abc123...          # Actual file blob
├── i1/
│   └── def456...
└── variants/             # Image variants cache
    └── ...
```

## Testing

Attachments work in test environment with isolated storage in `tmp/storage/`.

Example test:
```ruby
test "should attach avatar to user" do
  user = users(:alice)
  file = fixture_file_upload('avatar.png', 'image/png')
  user.avatar.attach(file)
  
  assert user.avatar.attached?
  assert_equal 'image/png', user.avatar.content_type
end
```

## Troubleshooting

### Images not displaying
- Check file permissions on `storage/` directory
- Verify `image_processing` gem is installed: `bundle list | grep image_processing`
- Check server logs for Active Storage errors

### Variant errors
- Ensure libvips is installed: `vips --version`
- On macOS: `brew install vips`
- On Ubuntu: `apt-get install libvips`

### File size validation not working
- Validations run on save, not on attach
- Check model validation is defined correctly
- Errors will appear in `model.errors.full_messages`

## Summary

Active Storage is now fully integrated with:
- ✅ User avatars with 5MB limit
- ✅ Post featured images with 10MB limit
- ✅ Image format validation (JPEG, PNG, GIF, WebP)
- ✅ Automatic image resizing with variants
- ✅ Upload forms in registration and post creation
- ✅ Display in all relevant views
- ✅ Authorization via existing policies
- ✅ Fallback to initials when no avatar exists
