class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_post_edit, only: [:edit, :update, :destroy]
  
  def index
    @posts = Post.all
  end
  def show
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
    @post = current_user ? current_user.posts.find_by!(slug: params[:id]) : Post.find_by!(slug: params[:id])
  rescue ActiveRecord::RecordNotFound
    # Fallback to finding by slug across all users' posts
    @post = Post.find_by!(slug: params[:id])
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

  def post_params
    params.require(:post).permit(:title, :body, :published_at)
  end
end