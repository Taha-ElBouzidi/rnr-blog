module Posts
  class PublishService < ApplicationService
    def initialize(post:, publisher:)
      @post = post
      @publisher = publisher
    end

    def call
      if @post.published?
        return Result.new(
          success: false, 
          post: @post, 
          error: "Post is already published",
          error_code: :already_published
        )
      end

      @post.published_at = Time.current
      @post.published_by = @publisher
      @post.slug = @post.generate_slug if @post.slug.blank?

      if @post.save
        Result.new(success: true, post: @post)
      else
        Result.new(
          success: false, 
          post: @post, 
          error: @post.errors.full_messages.join(', ')
        )
      end
    end
  end
end
