class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :user, optional: true

  validates :body, presence: true, length: { minimum: 3, maximum: 500 }

  def author_name
    user&.name || "Guest"
  end
end
