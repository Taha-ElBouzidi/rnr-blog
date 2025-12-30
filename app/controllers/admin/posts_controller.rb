module Admin
  class PostsController < BaseController
    def index
      @posts = Post.includes(:user).order(created_at: :desc)
      
      case params[:filter]
      when 'published'
        @posts = @posts.where.not(published_at: nil)
      when 'draft'
        @posts = @posts.where(published_at: nil)
      when 'no_cover'
        @posts = @posts.left_joins(:cover_image_attachment).where(active_storage_attachments: { id: nil })
      end
      
      if params[:search].present?
        @posts = @posts.where("title LIKE ? OR body LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
      end
    end

    def destroy
      @post = Post.find(params[:id])
      @post.destroy
      redirect_to admin_posts_path, notice: "✅ Post deleted successfully."
    end
  end
end
