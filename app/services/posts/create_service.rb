module Posts
  class CreateService < ApplicationService
    def initialize(user:, params:, publish_now: false)
      @user = user
      @params = params
      @publish_now = publish_now
    end

    def call
      post = Post.new(@params)
      post.user = @user

      if @publish_now
        post.slug = generate_slug(post.title) if post.title.present?
        post.published_at = Time.current
      end

      if post.save
        Result.new(success: true, post: post)
      else
        Result.new(success: false, post: post, error: post.errors.full_messages.join(', '))
      end
    end

    private

    def generate_slug(title)
      base_slug = title.parameterize
      slug = base_slug
      
      # Ensure uniqueness within user's posts
      counter = 1
      while @user.posts.where(slug: slug).exists?
        slug = "#{base_slug}-#{counter}"
        counter += 1
      end
      
      slug
    end
  end
end
