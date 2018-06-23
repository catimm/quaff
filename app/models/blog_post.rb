# == Schema Information
#
# Table name: blog_posts
#
#  id              :integer          not null, primary key
#  title           :string
#  subtitle        :string
#  status          :string
#  content         :text
#  image_url       :string
#  user_id         :integer
#  published_at    :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  beer_id         :integer
#  untappd_url     :string
#  ba_url          :string
#  slug            :string
#  content_opening :text
#

class BlogPost < ApplicationRecord
  # include friendly id
  extend FriendlyId
  friendly_id :title, use: :slugged
  
  belongs_to :user
  belongs_to :beer, optional: true
  
end
