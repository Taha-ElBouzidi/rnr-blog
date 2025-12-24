# RNR Blog

A full-featured Rails blog application with posts, comments, and user authentication.

## Features

### User Management
- User authentication with session-based login/logout
- Role-based access control (member, admin)
- Email validation with uniqueness constraint
- Test login system for easy user switching

### Posts
- Create, read, update, and delete posts
- Title validation (5-120 characters)
- Body validation (3-500 characters)
- Auto-generated SEO-friendly slugs from titles
- Slug-based URLs (e.g., `/posts/my-awesome-post`)
- Author attribution on all posts
- Published timestamp tracking
- Authorization: only post author or admin can edit/delete

### Comments
- Anyone can comment (logged-in users or guests)
- Guest comments labeled as "Guest"
- Comment validation (3-500 characters)
- Nested under posts with proper routing
- Display newest comments first
- Authorization: only comment author or admin can delete

### Data Quality
- Comprehensive validations on all models
- Foreign key constraints with proper indexes
- Unique email addresses for users
- Unique slugs per user for posts
- Restrict deletion of users with posts/comments

## Tech Stack

- **Ruby version**: 3.4.8
- **Rails version**: 8.1.1
- **Database**: SQLite3 (development/test)
- **Frontend**: ERB templates with inline CSS
- **Authentication**: Custom session-based auth (no gems)

## Setup Instructions

### Prerequisites
- Ruby 3.4.8
- Rails 8.1.1
- SQLite3

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Taha-ElBouzidi/rnr-blog.git
cd rnr-blog
```

2. Install dependencies:
```bash
bundle install
```

3. Setup the database:
```bash
bin/rails db:create
bin/rails db:migrate
```

4. (Optional) Create test users:
```bash
bin/rails runner "User.create(name: 'Alice Smith', email: 'alice@example.com'); User.create(name: 'Bob Johnson', email: 'bob@example.com'); User.create(name: 'Carol Davis', email: 'carol@example.com', role: 'admin')"
```

5. Start the server:
```bash
bin/rails server
```

6. Visit `http://localhost:3000`

## Usage

### Logging In
- Visit `/login` to see available users
- Select a user from the dropdown to log in as them
- No password required (testing mode)

### Creating Posts
- Must be logged in
- Click "New Post" in the navigation
- Fill in title and body (published_at is auto-set)
- Posts are automatically associated with the logged-in user

### Commenting
- Can comment without logging in (shows as "Guest")
- Logged-in users' names appear on their comments
- Comments display newest first

### Permissions
- **Regular users**: Can edit/delete only their own posts and comments
- **Admins**: Can edit/delete any post or comment
- **Guests**: Can only create comments

## Database Schema

### Users
- `name` (string)
- `email` (string, unique, validated format)
- `role` (string, default: "member")

### Posts
- `title` (string, 5-120 chars)
- `body` (text, 3-500 chars)
- `slug` (string, unique per user)
- `published_at` (datetime)
- `user_id` (foreign key, not null)

### Comments
- `body` (text, 3-500 chars)
- `post_id` (foreign key, not null)
- `user_id` (foreign key, nullable for guests)

## Development

### Running Tests
```bash
bin/rails test
```

### Rails Console
```bash
bin/rails console
```

### Database Reset
```bash
bin/rails db:reset
```

## Development Log

### Day 5 - Advanced Features & Performance Optimization (Dec 24, 2025)

#### 1. **ActiveRecord Scopes Implementation** 
*Location: `app/models/post.rb`*

Added five composable scopes for flexible post filtering:

```ruby
scope :published, -> { where.not(published_at: nil) }
scope :drafts, -> { where(published_at: nil) }
scope :recent, -> { order(created_at: :desc) }
scope :by_author, ->(user_id) { where(user_id: user_id) }
scope :search, ->(query) { 
  where("title LIKE ? OR body LIKE ?", 
    "%#{sanitize_sql_like(query)}%", 
    "%#{sanitize_sql_like(query)}%") 
}
```

**Technical Notes:**
- All scopes are chainable (e.g., `Post.published.by_author(1).search("rails")`)
- Search scope uses `sanitize_sql_like` to prevent SQL injection
- Scopes enable clean controller logic and reusable queries

#### 2. **Advanced Filtering System**
*Location: `app/helpers/posts_controller.rb` (PostsController#index)*

Updated index action with dynamic filtering:

```ruby
def index
  @posts = Post.includes(:user).recent
  
  # Admin-only status filter
  if current_user&.role == "admin"
    @posts = @posts.published if params[:status] == 'published'
    @posts = @posts.drafts if params[:status] == 'drafts'
  end
  
  @posts = @posts.by_author(params[:author_id]) if params[:author_id].present?
  @posts = @posts.search(params[:q]) if params[:q].present?
end
```

**Features:**
- Role-based filtering (status filter admin-only)
- Multi-parameter support (status, author, search)
- Eager loading with `includes(:user)` to prevent N+1 queries

#### 3. **Premium UI Redesign**
*Locations: `app/views/layouts/application.html.erb`, `app/views/posts/*.html.erb`*

Complete visual overhaul with modern design system:

**Design System:**
- **Typography**: Inter font family from Google Fonts
- **Colors**: Gradient backgrounds (purple-pink: `#667eea` → `#764ba2`)
- **Components**: Glass morphism cards with `backdrop-filter: blur(10px)`
- **Animations**: Smooth hover transitions on all interactive elements
- **Layout**: Responsive grid system with max-width containers

**Key Changes:**
- Sticky header with gradient logo and navigation
- Card-based post layout with colored accent borders
- Badge system for post status (Published/Draft)
- Avatar circles with user initials
- Enhanced filter UI with styled dropdowns and inputs
- Gradient buttons with hover effects
- Flash messages with emoji icons and color coding

**File Modifications:**
- `app/views/layouts/application.html.erb` - Global styles, header, navigation
- `app/views/posts/index.html.erb` - Grid layout, filter form
- `app/views/posts/show.html.erb` - Post detail view, comments section
- `app/views/posts/_post.html.erb` - Post card partial
- `app/views/posts/_form.html.erb` - Premium form styling

#### 4. **N+1 Query Prevention**
*Locations: `app/helpers/posts_controller.rb`*

Implemented eager loading to eliminate N+1 queries:

**Index Action:**
```ruby
@posts = Post.includes(:user).recent
```
- Loads all post authors in a single query using `WHERE id IN (...)`
- Prevents N+1 when displaying author names in post cards

**Show Action:**
```ruby
@post = Post.includes(comments: :user).find_by(slug: params[:id]) || 
        Post.includes(comments: :user).find(params[:id])
@comments = @post.comments.sort_by(&:created_at).reverse
```
- Eager loads comments and their associated users
- Sorts in memory to avoid additional database queries
- Handles both slug-based and ID-based lookups

**Performance Impact:**
- Index page: 4 queries total (regardless of post count)
- Show page: 4 queries total (regardless of comment count)
- Zero N+1 queries validated via log inspection

#### 5. **Counter Cache Implementation**
*Locations: `app/models/comment.rb`, `db/migrate/20251224204959_add_comments_count_to_posts.rb`*

Added `comments_count` column with automatic updates:

**Migration:**
```ruby
class AddCommentsCountToPosts < ActiveRecord::Migration[8.1]
  def up
    add_column :posts, :comments_count, :integer, default: 0, null: false
    
    # Backfill existing data
    Post.find_each do |post|
      Post.reset_counters(post.id, :comments)
    end
  end
  
  def down
    remove_column :posts, :comments_count
  end
end
```

**Model Configuration:**
```ruby
# app/models/comment.rb
belongs_to :post, counter_cache: true
```

**Usage in Views:**
```ruby
# app/views/posts/_post.html.erb
<%= post.comments_count %> # No database query!

# app/views/posts/show.html.erb
<%= @post.comments_count %> # Uses cached value
```

**Benefits:**
- Eliminates `COUNT(*)` queries when displaying comment counts
- Automatically increments/decrements on comment create/destroy
- Validated: Creates +1, Deletes -1, zero COUNT queries

#### 6. **Bug Fixes & Stability**

**Fixed `generate_slug` Nil User Error:**
```ruby
# app/models/post.rb
def generate_slug
  return if title.blank? || user.blank?
  # ... rest of slug generation
end
```
- Prevents error when unauthenticated users attempt to create posts

**Enhanced Post Routing:**
```ruby
# app/helpers/posts_controller.rb - set_post method
@post = Post.find_by(slug: params[:id]) || Post.find(params[:id])
```
- Handles both slug-based URLs and numeric IDs
- Ensures backward compatibility

**Slug Backfill:**
- Regenerated slugs for existing posts with `nil` slugs
- Ensures all posts have valid slug-based URLs

**CommentsController Slug Support:**
```ruby
# app/controllers/comments_controller.rb
@post = Post.find_by(slug: params[:post_id]) || Post.find(params[:post_id])
```
- Comments now work with slug-based post URLs

#### 7. **Performance Metrics**

**Query Analysis (Validated Dec 24, 2025):**

Index Page (`/posts`):
- Total queries: 4
- N+1 queries: 0
- COUNT queries: 0
- Scales: O(1) regardless of post count

Show Page (`/posts/:id`):
- Total queries: 4
- N+1 queries: 0
- COUNT queries: 0
- Scales: O(1) regardless of comment count

**Database Schema Updates:**
- Added `comments_count` column to `posts` table
- Index on `posts.slug` for faster lookups
- Counter cache backfilled for all existing posts

#### 8. **Files Modified Summary**

**Models:**
- `app/models/post.rb` - Added 5 scopes, fixed generate_slug
- `app/models/comment.rb` - Added counter_cache

**Controllers:**
- `app/helpers/posts_controller.rb` - Filtering logic, eager loading, slug support
- `app/controllers/comments_controller.rb` - Slug-based post lookup

**Views:**
- `app/views/layouts/application.html.erb` - Global premium design
- `app/views/posts/index.html.erb` - Filter UI, grid layout
- `app/views/posts/show.html.erb` - Post detail, comments section
- `app/views/posts/_post.html.erb` - Post card with comments_count badge
- `app/views/posts/_form.html.erb` - Premium form styling

**Migrations:**
- `db/migrate/20251224204959_add_comments_count_to_posts.rb` - Counter cache

**Total Lines Changed:** ~800+ (design overhaul + features + optimizations)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is available as open source.

## Author

Taha El Bouzidi
