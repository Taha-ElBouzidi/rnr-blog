class CommentMailer < ApplicationMailer
  def new_comment(comment:, recipient:)
    @comment = comment
    @post = comment.post
    @recipient = recipient
    @commenter = comment.user || OpenStruct.new(name: "Guest")
    
    mail(
      to: recipient.email,
      subject: "New comment on \"#{@post.title}\""
    )
  end
end
