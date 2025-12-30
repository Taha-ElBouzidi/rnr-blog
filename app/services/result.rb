class Result
  attr_reader :post, :comment, :error, :error_code

  def initialize(success:, post: nil, comment: nil, error: nil, error_code: nil)
    @success = success
    @post = post
    @comment = comment
    @error = error
    @error_code = error_code
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
