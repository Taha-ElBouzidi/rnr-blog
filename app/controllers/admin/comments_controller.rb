module Admin
  class CommentsController < BaseController
    def index
      @comments = Comment.includes(:user, :post).order(created_at: :desc)

      if params[:search].present?
        @comments = @comments.where("body LIKE ?", "%#{params[:search]}%")
      end
    end

    def destroy
      @comment = Comment.find(params[:id])
      @comment.destroy
      redirect_to admin_comments_path, notice: "✅ Comment deleted successfully."
    end

    def bulk_destroy
      if params[:comment_ids].present?
        Comment.where(id: params[:comment_ids]).destroy_all
        redirect_to admin_comments_path, notice: "✅ #{params[:comment_ids].size} comments deleted."
      else
        redirect_to admin_comments_path, alert: "❌ No comments selected."
      end
    end
  end
end
