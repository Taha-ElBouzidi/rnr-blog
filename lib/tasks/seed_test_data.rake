namespace :db do
  desc "Seed database with test posts and comments"
  task seed_test_data: :environment do
    puts "Creating test data..."
    
    # Get all users
    users = User.all
    
    if users.empty?
      puts "No users found. Please create users first."
      exit
    end
    
    # Create 30 posts
    30.times do |i|
      post = Post.create!(
        title: "Test Post #{i + 1}: #{['Amazing Discovery', 'Breaking News', 'Quick Tip', 'Tutorial', 'Discussion', 'Question'].sample}",
        body: "This is the body of test post #{i + 1}. #{['Lorem ipsum dolor sit amet, consectetur adipiscing elit.', 'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.', 'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore.'].sample * rand(2..5)}",
        user: users.sample,
        published_at: [nil, Time.current - rand(1..30).days].sample
      )
      
      # Create 3-8 comments per post
      rand(3..8).times do |j|
        Comment.create!(
          body: "This is comment #{j + 1} on post #{i + 1}. #{['Great post!', 'Thanks for sharing!', 'Very helpful information.', 'I have a question about this.', 'Interesting perspective.', 'Could you elaborate more?'].sample}",
          user: users.sample,
          post: post
        )
      end
      
      print '.'
    end
    
    puts "\n\nCreated #{Post.count} total posts and #{Comment.count} total comments!"
  end
end
