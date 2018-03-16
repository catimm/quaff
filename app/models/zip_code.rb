# == Schema Information
#
# Table name: zip_codes
#
#  id            :integer          not null, primary key
#  zip_code      :string
#  covered       :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  city          :string
#  state         :string
#  homepage_view :string
#  geo_zip       :string
#

class ZipCode < ActiveRecord::Base
end
