require "test_helper"

class PostPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = User.create!(
      name: "Admin User",
      email: "admin@test.com",
      password: "password123",
      role: "admin"
    )

    @member = User.create!(
      name: "Bob Member",
      email: "bob@test.com",
      password: "password123",
      role: "member"
    )

    @other_member = User.create!(
      name: "Carol Member",
      email: "carol@test.com",
      password: "password123",
      role: "member"
    )

    # Create a published post by member
    @published_post = Post.create!(
      user: @member,
      title: "Published Post Test",
      body: "This is a published post for testing",
      published_at: Time.current
    )

    # Create a draft post by member
    @draft_post = Post.create!(
      user: @member,
      title: "Draft Post Test",
      body: "This is a draft post for testing",
      published_at: nil
    )
  end

  # Rule: Anyone can see published posts
  test "guest can view published posts" do
    policy = PostPolicy.new(record: @published_post, user: nil)
    assert policy.show?, "Guest should be able to view published posts"
  end

  test "member can view published posts" do
    policy = PostPolicy.new(record: @published_post, user: @other_member)
    assert policy.show?, "Member should be able to view published posts"
  end

  test "admin can view published posts" do
    policy = PostPolicy.new(record: @published_post, user: @admin)
    assert policy.show?, "Admin should be able to view published posts"
  end

  test "guest cannot view draft posts" do
    policy = PostPolicy.new(record: @draft_post, user: nil)
    assert_not policy.show?, "Guest should NOT be able to view draft posts"
  end

  test "owner can view their own draft posts" do
    policy = PostPolicy.new(record: @draft_post, user: @member)
    assert policy.show?, "Owner should be able to view their own draft posts"
  end

  test "admin can view any draft posts" do
    policy = PostPolicy.new(record: @draft_post, user: @admin)
    assert policy.show?, "Admin should be able to view any draft posts"
  end

  test "other member cannot view draft posts they don't own" do
    policy = PostPolicy.new(record: @draft_post, user: @other_member)
    assert_not policy.show?, "Member should NOT be able to view drafts they don't own"
  end

  # Rule: Only owner or admin can edit
  test "owner can edit their own posts" do
    policy = PostPolicy.new(record: @published_post, user: @member)
    assert policy.update?, "Owner should be able to edit their own posts"
  end

  test "admin can edit any posts" do
    policy = PostPolicy.new(record: @published_post, user: @admin)
    assert policy.update?, "Admin should be able to edit any posts"
  end

  test "other member cannot edit posts they don't own" do
    policy = PostPolicy.new(record: @published_post, user: @other_member)
    assert_not policy.update?, "Member should NOT be able to edit posts they don't own"
  end

  test "guest cannot edit posts" do
    policy = PostPolicy.new(record: @published_post, user: nil)
    assert_not policy.update?, "Guest should NOT be able to edit posts"
  end

  # Rule: Only admin can delete
  test "admin can delete any posts" do
    policy = PostPolicy.new(record: @published_post, user: @admin)
    assert policy.destroy?, "Admin should be able to delete any posts"
  end

  test "owner cannot delete their own posts" do
    policy = PostPolicy.new(record: @published_post, user: @member)
    assert_not policy.destroy?, "Owner should NOT be able to delete their own posts (admin only)"
  end

  test "other member cannot delete posts" do
    policy = PostPolicy.new(record: @published_post, user: @other_member)
    assert_not policy.destroy?, "Member should NOT be able to delete posts"
  end

  test "guest cannot delete posts" do
    policy = PostPolicy.new(record: @published_post, user: nil)
    assert_not policy.destroy?, "Guest should NOT be able to delete posts"
  end

  # Additional tests for create
  test "logged in users can create posts" do
    policy = PostPolicy.new(record: Post.new, user: @member)
    assert policy.create?, "Logged in users should be able to create posts"
  end

  test "guests cannot create posts" do
    policy = PostPolicy.new(record: Post.new, user: nil)
    assert_not policy.create?, "Guests should NOT be able to create posts"
  end
end
