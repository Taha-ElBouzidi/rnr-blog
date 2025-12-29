class CommentsController < ApplicationController
  before_action :authenticate_user!, only: [:create]
  before_action :set_comment, only: [:destroy]
  
  def create
    @post = authorized_scope(Post).find_by(slug: params[:post_id]) || 
            authorized_scope(Post).find(params[:post_id])
    @comment = @post.comments.build
    authorize! @comment
    
    result = Comments::CreateService.call(post: @post, user: current_user, params: comment_params)
    @comment = result.post

    respond_to do |format|
      if result.success?
        format.html { redirect_to @post, notice: "💬 Comment added successfully!" }
        format.turbo_stream { flash.now[:notice] = "💬 Comment added successfully!" }
      else
        alert_message = friendly_error_message(result)
        
        format.html { redirect_to @post, alert: alert_message }
        format.turbo_stream { 
          flash.now[:alert] = alert_message
          render :create, status: :unprocessable_entity 
        }
      end
    end
  end

  def destroy
    authorize! @comment
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to @post, notice: "Comment deleted successfully." }
      format.turbo_stream { flash.now[:notice] = "Comment deleted successfully." }
    end
  end

  private
  
  def set_comment
    @comment = Comment.find(params[:id])
    @post = @comment.post
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to posts_path, alert: "Comment not found." }
      format.turbo_stream { head :no_content }
    end
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def friendly_error_message(result)
    case result.error_code
    when :spam_blocked
      "🚫 Your comment was blocked because it appears to contain spam. Please try again with different content."
    when :invalid
      if result.error.include?("can't be blank")
        "📝 Please enter a comment before submitting."
      elsif result.error.include?("too short")
        "✏️ Your comment is too short. Please write at least 3 characters."
      else
        "❌ #{result.error}"
      end
    else
      "⚠️ Failed to add comment. Please try again."
    end
  end
end
