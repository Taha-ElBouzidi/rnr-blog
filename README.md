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
