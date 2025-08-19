class Post < ApplicationRecord
  has_one_attached :file

  validates :title, presence: true, length: { maximum: 120 }
  validates :body, presence: true
  validate :validate_file_constraints

  MAX_FILE_SIZE = 5.megabytes
  ALLOWED_CONTENT_TYPES = %w[image/png image/jpeg image/gif]

  private

  def validate_file_constraints
    return unless file.attached?

    if file.blob.byte_size > MAX_FILE_SIZE
      errors.add(:file, "is too large (max #{MAX_FILE_SIZE / 1.megabyte}MB)")
    end

    unless ALLOWED_CONTENT_TYPES.include?(file.blob.content_type)
      errors.add(:file, "content type is not allowed")
    end
  end
end
