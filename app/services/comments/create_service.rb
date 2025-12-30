module Comments
  class CreateService < ApplicationService
    SPAM_KEYWORDS = %w[
      casino lottery winner bitcoin crypto
      click-here buy-now limited-time act-now
    ].freeze

    def initialize(post:, user:, params:)
      @post = post
      @user = user
      @params = params
    end

    def call
      comment = @post.comments.build(@params)
      comment.user = @user

      # Check for empty/spammy content
      if comment.body.blank?
        return Result.new(
          success: false,
          comment: comment,
          error: "Comment body can't be blank",
          error_code: :invalid
        )
      end

      if spam_detected?(comment.body)
        return Result.new(
          success: false,
          comment: comment,
          error: "Comment appears to be spam and was blocked",
          error_code: :spam_blocked
        )
      end

      # Create comment and update counter cache in transaction
      ActiveRecord::Base.transaction do
        unless comment.save
          return Result.new(
            success: false,
            comment: comment,
            error: comment.errors.full_messages.join(', '),
            error_code: :invalid
          )
        end

        # Counter cache is automatically updated by Rails, but we ensure it's in the same transaction
        @post.reload
      end

      # Send notifications asynchronously (won't slow down the request)
      send_notifications(comment)

      Result.new(success: true, comment: comment)
    end

    private

    def send_notifications(comment)
      recipients = []
      
      # Notify post author (if they have email and didn't write the comment)
      if comment.post.user&.email && comment.user_id != comment.post.user_id
        recipients << comment.post.user
      end
      
      # Notify previous commenters (excluding current commenter and post author)
      previous_commenters = comment.post.comments
        .where.not(user_id: nil)
        .where.not(id: comment.id)
        .where.not(user_id: comment.user_id)
        .where.not(user_id: comment.post.user_id)
        .includes(:user)
        .map(&:user)
        .uniq
      
      recipients += previous_commenters
      
      # Send emails asynchronously to all recipients
      recipients.uniq.each do |recipient|
        CommentMailer.new_comment(comment: comment, recipient: recipient).deliver_later
      end
    end

    def spam_detected?(body)
      return false if body.blank?
      
      normalized_body = body.downcase
      SPAM_KEYWORDS.any? { |keyword| normalized_body.include?(keyword) }
    end
  end
end
