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

    @authors = User.all # Cache for select options

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
  def show
    # Eager load comments and their users to avoid N+1
    @post = Post.includes(comments: :user).find_by(slug: params[:id]) || Post.includes(comments: :user).find(params[:id])
  end
  def new
    @post = Post.new
  end
  def create
    @post = Post.new(post_params)
    @post.user = current_user

    respond_to do |format|
      if @post.save
        format.html { redirect_to posts_path, notice: "Post was successfully created." }
        format.turbo_stream { flash.now[:notice] = "Post was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end
  def edit
  end
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to posts_path, notice: "Post was successfully updated." }
        format.turbo_stream { flash.now[:notice] = "Post was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end
  def destroy
    @post.destroy
    respond_to do |format|
      format.html { redirect_to posts_path, notice: "Post was successfully deleted." }
      format.turbo_stream { flash.now[:notice] = "Post was successfully deleted." }
    end
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

  def post_params
    params.require(:post).permit(:title, :body, :published_at)
  end
end