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

---

### Day 6 - Hotwire Frontend Architecture (Dec 25, 2025)

#### Overview
Transformed the application into a modern SPA-like experience using Hotwire (Turbo + Stimulus) while maintaining zero full-page reloads for CRUD operations. Implemented smooth animations, optimized code with DRY principles, and created reusable Stimulus controllers for enhanced user interactions.

#### Exercise 6.1 — Turbo Frames: Inline CRUD ✅

**Goal:** Create an inline user experience without full page reloads using Turbo Frames.

**Implementation:**

**1. Index Page with Turbo Frame** 
*Location: `app/views/posts/index.html.erb`*

```erb
<div class="container">
  <div class="flex justify-between items-center mb-4">
    <h1 class="text-2xl font-bold">All Posts</h1>
    <% if current_user %>
      <%= link_to "Create Post", new_post_path, 
          data: { turbo_frame: "new_post_frame" }, 
          class: "btn btn-success" %>
    <% end %>
  </div>

  <%= turbo_frame_tag "new_post_frame" %>

  <%= turbo_frame_tag "posts" do %>
    <% if @posts.any? %>
      <%= render @posts %>
    <% else %>
      <%= render "empty_state" %>
    <% end %>
  <% end %>
</div>
```

**2. New Post Form (Inline Loading)**
*Location: `app/views/posts/new.html.erb`*

```erb
<%= turbo_frame_tag "new_post_frame" do %>
  <div class="card">
    <h2 class="text-xl font-bold mb-3">New Post</h2>
    <%= render "form", post: @post %>
    <%= link_to "Cancel", posts_path, class: "btn btn-secondary mt-2" %>
  </div>
<% end %>
```

**3. Create Action with Turbo Stream**
*Location: `app/views/posts/create.turbo_stream.erb`*

```erb
<%= turbo_stream.update "flash_messages" do %>
  <%= render "shared/flash" %>
<% end %>

<%= turbo_stream.prepend "posts" do %>
  <div class="animate-slide-in">
    <%= render @post %>
  </div>
<% end %>

<%= turbo_stream.update "new_post_frame" do %>
  <!-- Close the form after successful creation -->
<% end %>
```

**4. Delete Action with Animation**
*Location: `app/views/posts/destroy.turbo_stream.erb`*

```erb
<%= turbo_stream.update "flash_messages" do %>
  <%= render "shared/flash" %>
<% end %>

<%= turbo_stream.action :remove_with_animation, dom_id(@post) %>
```

**5. Custom Turbo Stream Action**
*Location: `app/javascript/turbo_stream_actions.js`*

```javascript
import { StreamActions } from "@hotwired/turbo"

StreamActions.remove_with_animation = function() {
  const targetElement = this.targetElements[0]
  
  if (targetElement) {
    targetElement.classList.add('animate-slide-out')
    
    setTimeout(() => {
      targetElement.remove()
    }, 300)
  }
}
```

**6. Smooth Animations**
*Location: `app/assets/stylesheets/application.tailwind.css`*

```css
@keyframes slideInDown {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes slideOutUp {
  from {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
  to {
    opacity: 0;
    transform: translateY(-20px) scale(0.95);
  }
}

.animate-slide-in {
  animation: slideInDown 0.4s ease-out forwards;
}

.animate-slide-out {
  animation: slideOutUp 0.3s ease-in forwards;
}
```

**Results:**
- ✅ Posts list wrapped in `<turbo-frame id="posts">`
- ✅ "New Post" loads form inline without page reload
- ✅ Form submission prepends post to list with slide-in animation
- ✅ Delete button removes post with slide-out animation
- ✅ No custom JavaScript needed - just Turbo + CSS animations
- ✅ Zero full-page redirects

---

#### Exercise 6.2 — Stimulus: UI Behavior ✅

**Goal:** Add UI behaviors using Stimulus for form interactions.

**Implementation:**

**1. Form Submit Controller (Button Disable + Loading State)**
*Location: `app/javascript/controllers/form_submit_controller.js`*

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit"]
  
  disableSubmit() {
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "Saving..."
  }
  
  enable() {
    this.submitTarget.disabled = false
    this.submitTarget.textContent = this.originalText
  }
  
  connect() {
    this.originalText = this.submitTarget.textContent
  }
}
```

**Usage in Post Form:**
*Location: `app/views/posts/_form.html.erb`*

```erb
<%= form_with(model: post, data: { 
  controller: "form-submit",
  action: "turbo:submit-start->form-submit#disableSubmit 
           turbo:submit-end->form-submit#enable"
}) do |form| %>
  <%= form.text_field :title, class: "form-input" %>
  <%= form.text_area :body, rows: 8, class: "form-textarea" %>
  <%= form.submit "Save Post", class: "btn btn-success", 
      data: { form_submit_target: "submit" } %>
<% end %>
```

**2. Autosubmit Controller (Filter Auto-update)**
*Location: `app/javascript/controllers/autosubmit_controller.js`*

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search"]
  
  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 300)
  }
  
  clear() {
    this.searchTarget.value = ""
    this.element.requestSubmit()
  }
}
```

**Usage in Filter Form:**
*Location: `app/views/posts/index.html.erb`*

```erb
<%= form_with url: posts_path, method: :get, 
    data: { 
      turbo_frame: "posts", 
      turbo_action: "advance",
      controller: "autosubmit" 
    } do |f| %>
  
  <%= f.text_field :q, value: params[:q], 
      placeholder: "Search posts...", 
      class: "form-input", 
      data: { 
        action: "input->autosubmit#submit",
        autosubmit_target: "search" 
      } %>
  
  <%= f.select :author_id, 
      options_for_select([['All Authors', '']] + @authors.map { |u| [u.name, u.id] }),
      {}, 
      class: "form-select",
      data: { action: "change->autosubmit#submit" } %>
  
  <button type="button" 
          data-action="click->autosubmit#clear" 
          class="btn btn-secondary">
    Clear
  </button>
<% end %>
```

**3. Filter with Turbo Frame**
*Location: `app/views/posts/index.turbo_stream.erb`*

```erb
<%= turbo_stream.update "posts" do %>
  <% if @posts.any? %>
    <%= render @posts %>
  <% else %>
    <%= render "empty_state" %>
  <% end %>
<% end %>
```

**Results:**
- ✅ Submit button disables on click with "Saving..." text
- ✅ Filter form auto-submits as you type (300ms debounce)
- ✅ Clear button resets search instantly
- ✅ No business logic in Stimulus - only UI behavior
- ✅ Results update without page refresh

---

#### Additional Improvements

**Tailwind CSS Integration**
*Location: `app/assets/stylesheets/application.tailwind.css`*

Migrated from inline styles to Tailwind CSS utility classes with custom components:

```css
@import "tailwindcss";

@layer components {
  .btn {
    @apply px-4 py-2 rounded-md font-semibold text-sm transition-colors;
  }
  
  .btn-success {
    @apply bg-green-600 text-white hover:bg-green-700;
  }
  
  .btn-danger {
    @apply bg-red-500 text-white hover:bg-red-600;
  }
  
  .card {
    @apply bg-white rounded-lg shadow p-4 mb-4;
  }
}
```

**6. Enhanced Comments System**

**Inline Comment Creation:**
*Location: `app/views/comments/create.turbo_stream.erb`*

```erb
<%= turbo_stream.prepend "comments" do %>
  <div class="animate-slide-in">
    <%= turbo_frame_tag dom_id(@comment) do %>
      <%= render "comments/comment", comment: @comment, post: @post %>
    <% end %>
  </div>
<% end %>

<%= turbo_stream.update "new_comment_form" do %>
  <%= form_with model: [@post, Comment.new], ... %>
<% end %>
```

**Comment Deletion with Animation:**
*Location: `app/views/comments/destroy.turbo_stream.erb`*

```erb
<%= turbo_stream.action :remove_with_animation, dom_id(@comment) %>
```


**8. Test Data Generation**

Created rake task to generate test data:
*Location: `lib/tasks/seed_test_data.rake`*

```ruby
namespace :db do
  desc "Seed database with test posts and comments"
  task seed_test_data: :environment do
    users = User.all
    
    30.times do |i|
      post = Post.create!(
        title: "Test Post #{i + 1}: #{['Amazing', 'Breaking News'].sample}",
        body: "Lorem ipsum..." * rand(2..5),
        user: users.sample,
        published_at: [nil, Time.current - rand(1..30).days].sample
      )
      
      rand(3..8).times do |j|
        Comment.create!(
          body: "Comment #{j + 1}...",
          user: users.sample,
          post: post
        )
      end
    end
  end
end
```

**Usage:**
```bash
bin/rake db:seed_test_data
```

**Result:** Created 32 posts and 155 comments for comprehensive testing

---

#### Technical Stack Updates

**Frontend:**
- **Turbo Rails**: SPA-like interactions without JavaScript
- **Stimulus 3.x**: Lightweight JavaScript for UI behavior
- **Tailwind CSS v4.1.18**: Utility-first CSS framework
- **esbuild**: JavaScript bundler

**Key Dependencies:**
- `@hotwired/turbo-rails`
- `@hotwired/stimulus`
- `tailwindcss-rails`

---

#### Files Modified Summary

**New Files Created:**
- `app/javascript/controllers/form_submit_controller.js`
- `app/javascript/controllers/autosubmit_controller.js`
- `app/javascript/turbo_stream_actions.js`
- `app/controllers/concerns/authorizable.rb`
- `app/views/posts/_empty_state.html.erb`
- `app/views/posts/index.turbo_stream.erb`
- `app/views/posts/new.turbo_stream.erb`
- `app/views/posts/edit.turbo_stream.erb`
- `lib/tasks/seed_test_data.rake`

**Modified Files:**
- `app/assets/stylesheets/application.tailwind.css` - Added animations and Tailwind components
- `app/controllers/application_controller.rb` - Include Authorizable concern
- `app/controllers/posts_controller.rb` - Optimized with cached @authors
- `app/controllers/comments_controller.rb` - Added error handling
- `app/models/post.rb` - Improved search scope, default comment ordering
- `app/views/posts/index.html.erb` - Turbo frames, autosubmit controller
- `app/views/posts/show.html.erb` - Turbo frames for comments, disabled turbo for delete
- `app/views/posts/_post.html.erb` - Turbo frame per post
- `app/views/posts/_form.html.erb` - Form submit controller
- `app/views/posts/create.turbo_stream.erb` - Animation on create
- `app/views/posts/destroy.turbo_stream.erb` - Custom remove action
- `app/views/comments/_comment.html.erb` - Added persisted? check
- `app/views/comments/create.turbo_stream.erb` - Animation, fixed form reset
- `app/views/comments/destroy.turbo_stream.erb` - Custom remove action
- `app/javascript/application.js` - Import turbo stream actions

**Total Lines Changed:** ~450+ (Turbo + Stimulus + animations + optimizations)

---

#### Performance & User Experience

**Zero Full-Page Reloads:**
- Post creation: Inline form → Submit → Instant prepend
- Post deletion: Click → Smooth fade out → Remove
- Comment creation: Type → Submit → Slide in above
- Comment deletion: Click → Fade out → Remove
- Filtering: Type → 300ms debounce → Results update

**Smooth Animations:**
- Create: 0.4s slide-in-down + fade-in
- Delete: 0.3s slide-out-up + fade-out + scale-down
- All transitions use CSS transforms (GPU-accelerated)

**Accessibility:**
- Disabled button states during submission
- Visual feedback ("Saving..." text)
- No layout shift during animations
- Semantic HTML with proper ARIA

---

#### Screenshots & Demos

Here's the app in action showing all the Turbo and Stimulus features:

**Screenshots:**

![Posts Index](docs/images/01_posts_index.png)
*Posts index page with filters and inline actions*

![Inline Form](docs/images/02_inline_post_creation.png)
*Creating a new post without leaving the page*

![Post with Comments](docs/images/03_post_detail_comments.png)
*Post detail page with inline comments*

![Admin Filters](docs/images/04_admin_filter_view.png)
*Admin users get an extra status filter*

**Demo Videos:**

![Create Post](docs/images/demo_01_create_post_inline.gif)
*Click "New Post", fill the form, and watch it appear at the top - no page reload*

![Delete Post](docs/images/demo_02_delete_post.gif)
*Posts fade out smoothly when deleted*

![Auto Filter](docs/images/demo_04_autosubmit_filter.gif)
*Search filters posts automatically as you type (with 300ms debounce)*

![Clear Filter](docs/images/demo_05_clear_filter.gif)
*One click to clear search and see all posts again*

![Comments](docs/images/demo_06_comments_lifecycle.gif)
*Add and delete comments inline with smooth animations*

![Edit Post](docs/images/demo_07_edit_post_inline.gif)
*Edit posts right in the list - form appears inline and updates instantly*

---

#### Learning Outcomes

**Turbo Frames:**
- Understanding frame-based page composition
- Lazy-loaded frames vs eager frames
- Breaking out of frames with `_top`
- Turbo Stream responses for dynamic updates

**Turbo Streams:**
- Seven actions: append, prepend, replace, update, remove, before, after
- Custom stream actions (e.g., `remove_with_animation`)
- Combining multiple streams in one response
- Stream rendering from controllers

**Stimulus:**
- Separation of concerns (UI only, no business logic)
- Target pattern for DOM references
- Action pattern for event handling
- Lifecycle callbacks (connect, disconnect)
- Debouncing user input

**Performance:**
- Reduced server load (partial rendering vs full pages)
- Faster perceived performance (instant UI updates)
- GPU-accelerated CSS animations
- Efficient Turbo Drive caching

**Best Practices:**
- DRY with concerns (Authorizable)
- Shared partials (empty_state)
- Consistent naming conventions (Turbo frame IDs)
- Error handling for race conditions (deleted records)

---

**Total Lines Changed:** ~450+ (design overhaul + features + optimizations)

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
