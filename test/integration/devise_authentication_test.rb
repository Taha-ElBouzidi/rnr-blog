require "test_helper"

class DeviseAuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:alice)
  end

  test "✓ Session persists across requests" do
    # Login
    post user_session_path, params: {
      user: { email: @user.email, password: 'password123' }
    }
    
    # Should be logged in
    assert_not_nil session[:user_id] || cookies['_session_id']
    
    # Navigate to posts index
    get posts_path
    assert_response :success
    
    # Navigate to another page - session should persist
    get menu_path
    assert_response :success
    
    # Try to create a post (requires authentication)
    get new_post_path
    assert_response :success, "Session should persist - user can access protected page"
  end

  test "✓ Logging out clears session" do
    # Login first
    sign_in @user
    
    # Verify logged in
    get new_post_path
    assert_response :success
    
    # Logout
    delete destroy_user_session_path
    
    # Try to access protected page
    get new_post_path
    assert_redirected_to new_user_session_path, "Should redirect to login after logout"
    
    # Follow redirect
    follow_redirect!
    assert_response :success
    assert_match /sign in/i, response.body.downcase
  end

  test "✓ Protected pages redirect unauthenticated users" do
    # Ensure not logged in
    get new_post_path
    
    # Should redirect to login
    assert_redirected_to new_user_session_path
    
    # Follow redirect to login page
    follow_redirect!
    assert_response :success
    assert_select 'h1', 'Login'
  end

  test "✓ Redirects back to intended page after login" do
    # Try to access protected page while not logged in
    get new_post_path
    assert_redirected_to new_user_session_path
    
    # Login
    post user_session_path, params: {
      user: { email: @user.email, password: 'password123' }
    }
    
    # Should redirect back to the intended page (new_post_path)
    assert_redirected_to new_post_path, "Should redirect to originally requested page"
  end

  test "✓ Session tracking increments sign_in_count" do
    initial_count = @user.sign_in_count || 0
    
    # Login
    post user_session_path, params: {
      user: { email: @user.email, password: 'password123' }
    }
    
    # Reload user and check count increased
    @user.reload
    assert_equal initial_count + 1, @user.sign_in_count
    assert_not_nil @user.current_sign_in_at
    assert_not_nil @user.current_sign_in_ip
  end
end
