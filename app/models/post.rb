class Post < ApplicationRecord
  belongs_to :user
  belongs_to :contest
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  def save_tag(sent_tags)
    current_tags = tags.pluck(:name) unless tags.nil?
    @old_tags = current_tags - sent_tags
    new_tags = sent_tags - current_tags

    # 古いタグがあれば古いタグを消す
    unless @old_tags.blank?
      @old_tags.each do |old|
        tags.delete(Tag.find_by(name: old))
      end
    end

    # 新しいタグを保存
    new_tags.each do |new|
      new_post_tag = Tag.find_or_create_by(name: new)
      tags << new_post_tag
    end
  end
end
