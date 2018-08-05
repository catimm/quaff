# == Schema Information
#
# Table name: curation_requests
#
#  id                     :integer          not null, primary key
#  account_id             :integer
#  drink_type             :string
#  number_of_beers        :integer
#  number_of_large_drinks :integer
#  delivery_date          :datetime
#  additional_requests    :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  drink_option_id        :integer
#  user_id                :integer
#  number_of_ciders       :integer
#  number_of_glasses      :integer
#

class CurationRequest < ApplicationRecord

end
