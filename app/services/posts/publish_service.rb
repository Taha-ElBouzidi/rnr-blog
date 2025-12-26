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

      if @post.save
        broadcast_status_update(@post)
        Result.new(success: true, post: @post)
      else
        Result.new(
          success: false,
          post: @post,
          error: @post.errors.full_messages.join(', '),
          error_code: :invalid
        )
      end
    end

    private

    def broadcast_status_update(post)
      post.broadcast_replace_to(
        "post_#{post.id}_status",
        target: "post_#{post.id}_status",
        partial: "posts/status_badge",
        locals: { post: post }
      )
    end
  end
end
