class PostsController < ApplicationController
  before_action :require_login, only: [:new, :create]
  before_action :set_post, only: [:edit, :update, :destroy]
  before_action :authorize_post_edit, only: [:edit, :update, :destroy]
  
  def index
    @posts = Post.includes(:user).recent
    
    # Only admins can filter by status
    if current_user&.role == "admin"
      @posts = @posts.published if params[:status] == 'published'
      @posts = @posts.drafts if params[:status] == 'drafts'
    end
    
    @posts = @posts.by_author(params[:author_id]) if params[:author_id].present?
    
    @posts = @posts.search(params[:q]) if params[:q].present?
  end
  def show
    # Eager load comments (ordered) and their users to avoid N+1
    @post = Post.includes(comments: :user).find_by(slug: params[:id]) || Post.includes(comments: :user).find(params[:id])
    # Sort comments in memory to avoid additional query
    @comments = @post.comments.sort_by(&:created_at).reverse
  end
  def new
    @post = Post.new
  end
  def create
    @post = Post.new(post_params)
    @post.user = current_user

    if @post.save
      redirect_to posts_path, notice: "Post was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end
  def edit
  end
  def update
    if @post.update(post_params)
      redirect_to posts_path, notice: "Post was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    @post.destroy
    redirect_to posts_path, notice: "Post was successfully deleted."
  end

  private

  def set_post
    # Try to find by slug first, then fall back to ID
    @post = Post.find_by(slug: params[:id]) || Post.find(params[:id])
  end

  def authorize_post_edit
    unless can_edit_post?(@post)
      redirect_to posts_path, alert: "You are not authorized to perform this action."
    end
  end

  def can_edit_post?(post)
    current_user && (current_user.id == post.user_id || current_user.role == "admin")
  end
  helper_method :can_edit_post?

  def require_login
    unless current_user
      redirect_to posts_path, alert: "You must be logged in to create a post."
    end
  end

  def post_params
    params.require(:post).permit(:title, :body, :published_at)
  end
end