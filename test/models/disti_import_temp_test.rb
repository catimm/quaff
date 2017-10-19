# == Schema Information
#
# Table name: disti_import_temps
#
#  id                :integer          not null, primary key
#  disti_item_number :integer
#  maker_name        :string
#  maker_knird_id    :integer
#  drink_name        :string
#  format            :string
#  size_format_id    :integer
#  drink_cost        :decimal(, )
#  drink_price       :decimal(, )
#  distributor_id    :integer
#  disti_upc         :string
#  min_quantity      :integer
#  regular_case_cost :decimal(, )
#  current_case_cost :decimal(, )
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'test_helper'

class DistiImportTempTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
