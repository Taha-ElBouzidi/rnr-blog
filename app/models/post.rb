class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy

  validates :title, presence: true, length: { minimum: 5, maximum: 120 }
  validates :body, presence: true, length: { minimum: 3, maximum: 500 }
  validates :slug, uniqueness: { scope: :user_id }

  before_validation :generate_slug
  before_validation :set_published_at, on: :create

  def published?
    published_at.present?
  end

  def publish!
    update!(published_at: Time.current)
  end

  def to_param
    slug
  end

  private

  def generate_slug
    return if title.blank?
    base_slug = title.parameterize
    self.slug = base_slug
    
    # Ensure uniqueness within user's posts
    counter = 1
    while user.posts.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end

  def set_published_at
    self.published_at ||= Time.current
  end
end
