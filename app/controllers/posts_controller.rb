class PostsController < ApplicationController
  before_action :store_user_location!, if: :storable_location?
  before_action :authenticate_user!, only: [ :new, :create ]
  before_action :set_post, only: [ :edit, :update, :destroy, :publish, :unpublish ]

  def index
    authorize! Post, to: :index?
    @posts = authorized_scope(Post.includes(:user).recent)

    # Filter by status (published/drafts)
    if params[:status].present? && current_user
      if params[:status] == "published"
        @posts = @posts.published
      elsif params[:status] == "drafts"
        # Members see only their own drafts, admins see all drafts
        if current_user.role == "admin"
          @posts = @posts.drafts
        else
          @posts = @posts.drafts.where(user_id: current_user.id)
        end
      end
    end

    @posts = @posts.by_author(params[:author_id]) if params[:author_id].present?

    @posts = @posts.search(params[:q]) if params[:q].present?

    # Only load necessary columns for author filter
    @authors = User.select(:id, :name, :email).order(:name)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    # Eager load comments and their users to avoid N+1
    # Find by slug first, fallback to ID
    @post = Post.includes(comments: :user).find_by(slug: params[:id]) ||
            Post.includes(comments: :user).find(params[:id])
    authorize! @post, to: :show?
  end

  def new
    @post = Post.new
    authorize! @post, to: :create?
  end

  def create
    @post = Post.new
    authorize! @post, to: :create?

    publish_now = params[:commit] == "Publish"
    result = Posts::CreateService.call(
      user: current_user,
      params: post_params,
      publish_now: publish_now
    )
    @post = result.post

    respond_to do |format|
      if result.success?
        message = publish_now ? "Post was successfully published!" : "Post was saved as draft."
        format.html { redirect_to posts_path, notice: message }
        format.turbo_stream { flash.now[:notice] = message }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize! @post, to: :update?
  end

  def update
    authorize! @post, to: :update?
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
    authorize! @post, to: :destroy?
    @post.destroy
    respond_to do |format|
      format.html { redirect_to posts_path, notice: "Post was successfully deleted." }
      format.turbo_stream { flash.now[:notice] = "Post was successfully deleted." }
    end
  end

  def publish
    authorize! @post, to: :publish?
    result = Posts::PublishService.call(post: @post, publisher: current_user)

    respond_to do |format|
      if result.success?
        format.html { redirect_to posts_path(status: "published"), notice: "📢 Post was successfully published!" }
        format.turbo_stream do
          flash.now[:notice] = "📢 Post was successfully published!"
          render turbo_stream: [
            turbo_stream.remove(ActionView::RecordIdentifier.dom_id(@post)),
            turbo_stream.update("flash_messages", partial: "shared/flash")
          ]
        end
      else
        alert_message = result.error_code == :already_published ? result.error : "Failed to publish post"
        format.html { redirect_to posts_path, alert: alert_message }
        format.turbo_stream { flash.now[:alert] = alert_message }
      end
    end
  end

  def unpublish
    authorize! @post, to: :unpublish?
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
    # Find by slug first, then fall back to ID
    @post = Post.find_by(slug: params[:id]) || Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body, :published_at, :cover_image)
  end

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end
end
