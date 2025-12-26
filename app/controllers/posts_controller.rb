class PostsController < ApplicationController
  before_action :require_login, only: [:new, :create]
  before_action :set_post, only: [:edit, :update, :destroy, :publish, :unpublish]
  before_action :authorize_post_edit, only: [:edit, :update, :destroy, :publish, :unpublish]
  
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
    publish_now = params[:post][:publish_now] == "1" || params[:commit] == "Publish"
    result = Posts::CreateService.call(
      user: current_user, 
      params: post_params,
      publish_now: publish_now
    )
    @post = result.post

    respond_to do |format|
      if result.success?
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

  def publish
    result = Posts::PublishService.call(post: @post, publisher: current_user)

    respond_to do |format|
      if result.success?
        format.html { redirect_to posts_path, notice: "📢 Post was successfully published!" }
        format.turbo_stream { flash.now[:notice] = "📢 Post was successfully published!" }
      else
        alert_message = result.error_code == :already_published ? result.error : "Failed to publish post"
        format.html { redirect_to posts_path, alert: alert_message }
        format.turbo_stream { flash.now[:alert] = alert_message }
      end
    end
  end

  def unpublish
    if @post.published?
      @post.update!(published_at: nil, published_by_id: nil)
      broadcast_status_update(@post)
      respond_to do |format|
        format.html { redirect_to posts_path, notice: "📝 Post was unpublished and saved as draft." }
        format.turbo_stream { flash.now[:notice] = "📝 Post was unpublished and saved as draft." }
      end
    else
      redirect_to posts_path, alert: "Post is already a draft."
    end
  end

  private

  def broadcast_status_update(post)
    post.broadcast_replace_to(
      "post_#{post.id}_status",
      target: "post_#{post.id}_status",
      partial: "posts/status_badge",
      locals: { post: post }
    )
  end

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