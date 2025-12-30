require "test_helper"

class PostCoverImageTest < ActiveSupport::TestCase
  def setup
    @user = users(:alice)
    @post = Post.new(
      title: "Test Post",
      body: "Test body content",
      user: @user
    )
  end

  test "post saves without cover_image" do
    assert @post.save, "Post should save without cover_image"
  end

  test "rejects GIF format" do
    @post.cover_image.attach(
      io: StringIO.new("fake image"),
      filename: "test.gif",
      content_type: "image/gif"
    )

    assert_not @post.save
    assert_includes @post.errors.full_messages.join, "must be a JPEG, PNG, or WebP"
  end

  test "rejects files larger than 5MB" do
    large_data = "x" * (6 * 1024 * 1024)
    @post.cover_image.attach(
      io: StringIO.new(large_data),
      filename: "large.jpg",
      content_type: "image/jpeg"
    )

    assert_not @post.save
    assert_includes @post.errors.full_messages.join, "must be less than 5MB"
  end

  test "accepts valid JPEG" do
    @post.cover_image.attach(
      io: StringIO.new("small jpeg"),
      filename: "valid.jpg",
      content_type: "image/jpeg"
    )

    assert @post.save, "Post should save with valid JPEG"
  end

  test "accepts valid PNG" do
    @post.cover_image.attach(
      io: StringIO.new("small png"),
      filename: "valid.png",
      content_type: "image/png"
    )

    assert @post.save, "Post should save with valid PNG"
  end

  test "accepts valid WebP" do
    @post.cover_image.attach(
      io: StringIO.new("small webp"),
      filename: "valid.webp",
      content_type: "image/webp"
    )

    assert @post.save, "Post should save with valid WebP"
  end

  test "variant processing is lazy" do
    @post.cover_image.attach(
      io: StringIO.new("test image"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )
    @post.save!

    # Creating a variant does not immediately process it
    variant = @post.cover_image.variant(resize_to_limit: [400, 300])
    assert_instance_of ActiveStorage::Variant, variant
    
    # Variant is processed only when needed (e.g., when calling .processed or rendering)
    assert_respond_to variant, :processed
  end
end
