class CommentsController < ApplicationController
  def create
    @post = Post.find(params[:post_id])
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to @post, notice: "Comment added successfully."
    else
      redirect_to @post, alert: "Failed to add comment: #{@comment.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @post = @comment.post
    
    if current_user && (current_user.id == @comment.user_id || current_user.role == "admin")
      @comment.destroy
      redirect_to @post, notice: "Comment deleted successfully."
    else
      redirect_to @post, alert: "You are not authorized to delete this comment."
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end
end
