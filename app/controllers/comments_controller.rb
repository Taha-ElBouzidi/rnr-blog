class CommentsController < ApplicationController
  before_action :require_login, only: [:create]
  before_action :set_comment, only: [:destroy]
  before_action :authorize_comment_delete, only: [:destroy]
  
  def create
    # Find post by slug or ID
    @post = Post.find_by(slug: params[:post_id]) || Post.find(params[:post_id])
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    respond_to do |format|
      if @comment.save
        format.html { redirect_to @post, notice: "Comment added successfully." }
        format.turbo_stream { flash.now[:notice] = "Comment added successfully." }
      else
        format.html { redirect_to @post, alert: "Failed to add comment: #{@comment.errors.full_messages.join(', ')}" }
        format.turbo_stream { flash.now[:alert] = "Failed to add comment: #{@comment.errors.full_messages.join(', ')}" }
      end
    end
  end

  def destroy
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

  def authorize_comment_delete
    unless can_delete_comment?(@comment)
      redirect_to @post, alert: "You are not authorized to delete this comment."
    end
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
