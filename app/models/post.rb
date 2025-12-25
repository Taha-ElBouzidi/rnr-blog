class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, -> { order(created_at: :desc) }, dependent: :destroy

  # Scopes
  scope :published, -> { where.not(published_at: nil) }
  scope :drafts, -> { where(published_at: nil) }
  scope :recent, -> { order(published_at: :desc, created_at: :desc) }
  scope :by_author, ->(user_id) { where(user_id: user_id) }
  scope :search, ->(query) { 
    sanitized = sanitize_sql_like(query)
    where("title LIKE :q OR body LIKE :q", q: "%#{sanitized}%") 
  }

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
    slug.presence || id.to_s
  end

  private

  def generate_slug
    return if title.blank?
    return if user.blank?  # Skip slug generation if no user
    
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
