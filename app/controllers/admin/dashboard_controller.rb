module Admin
  class DashboardController < BaseController
    def index
      @stats = {
        total_users: User.count,
        total_posts: Post.count,
        published_posts: Post.where.not(published_at: nil).count,
        draft_posts: Post.where(published_at: nil).count,
        total_comments: Comment.count,
        admin_users: User.where(role: "admin").count
      }

      @recent_users = User.order(created_at: :desc).limit(5)
      @recent_posts = Post.order(created_at: :desc).limit(5)
      @recent_comments = Comment.includes(:user, :post).order(created_at: :desc).limit(10)
    end
  end
end
