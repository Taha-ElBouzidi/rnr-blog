class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  has_many :posts, dependent: :restrict_with_error
  has_many :comments, dependent: :restrict_with_error

  # Active Storage
  has_one_attached :avatar

  # Role validation
  VALID_ROLES = %w[member admin].freeze
  validates :role, presence: true, inclusion: { in: VALID_ROLES }

  validates :name, presence: true
  # Email validation is handled by Devise's :validatable module

  # Avatar validation
  validate :avatar_format

  def admin?
    role == "admin"
  end

  def member?
    role == "member"
  end

  private

  def avatar_format
    return unless avatar.attached?

    unless avatar.content_type.in?(%w[image/jpeg image/jpg image/png image/gif])
      errors.add(:avatar, "must be a JPEG, PNG, or GIF image")
    end

    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, "must be less than 5MB")
    end
  end
end
