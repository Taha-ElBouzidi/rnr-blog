class Post < ApplicationRecord
  broadcasts_refreshes
  
  belongs_to :user
  belongs_to :published_by, class_name: 'User', optional: true
  has_many :comments, -> { order(created_at: :desc) }, dependent: :destroy
  
  # Active Storage
  has_one_attached :cover_image

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
  validates :body, presence: true, length: { minimum: 10, maximum: 500 }
  validates :slug, uniqueness: { scope: :user_id }
  
  # Cover image validation
  validate :cover_image_format

  before_validation :generate_slug

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
    return unless user_id  # Skip slug generation if no user_id
    
    base_slug = title.parameterize
    self.slug = base_slug
    
    # Ensure uniqueness within user's posts
    counter = 1
    while Post.where(user_id: user_id, slug: slug).where.not(id: id).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
  
  def cover_image_format
    return unless cover_image.attached?
    
    unless cover_image.content_type.in?(%w[image/jpeg image/jpg image/png image/webp])
      errors.add(:cover_image, 'must be a JPEG, PNG, or WebP image')
    end
    
    if cover_image.byte_size > 5.megabytes
      errors.add(:cover_image, 'must be less than 5MB')
    end
  end
end
