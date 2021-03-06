# == Schema Information
#
# Table name: disti_import_temps
#
#  id                    :integer          not null, primary key
#  disti_item_number     :integer
#  maker_name            :string
#  maker_knird_id        :integer
#  drink_name            :string
#  format                :string
#  size_format_id        :integer
#  drink_cost            :decimal(, )
#  drink_price_four_five :decimal(, )
#  distributor_id        :integer
#  disti_upc             :string
#  min_quantity          :integer
#  regular_case_cost     :decimal(, )
#  current_case_cost     :decimal(, )
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  drink_price_five_zero :decimal(5, 2)
#  drink_price_five_five :decimal(5, 2)
#

class DistiImportTemp < ApplicationRecord
  require 'csv'
  
  # method to quickly upload CSV file
  def self.import(file)
    CSV.foreach(file.path, :encoding => 'windows-1251:utf-8', headers: true) do |row|
      DistiImportTemp.create! row.to_hash
    end
  end
  
end
