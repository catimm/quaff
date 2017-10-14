# == Schema Information
#
# Table name: disti_inventories
#
#  id                :integer          not null, primary key
#  beer_id           :integer
#  size_format_id    :integer
#  drink_cost        :decimal(5, 2)
#  drink_price       :decimal(5, 2)
#  distributor_id    :integer
#  disti_item_number :integer
#  disti_upc         :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  min_quantity      :integer
#  regular_case_cost :decimal(5, 2)
#  current_case_cost :decimal(5, 2)
#

class DistiInventory < ActiveRecord::Base
  belongs_to :beer
  belongs_to :size_format
  belongs_to :distributor
  
  require 'csv'
  # create a class method to import disti inventory from CSV files
  def self.import(file)

    # a block that runs through loop in CSV data
    CSV.foreach(file.path, :encoding => 'windows-1251:utf-8', headers: true) do |row, index|
      if index == 0
        # first remove all available drinks currently in the Disti Inventory table for this Disti
        @all_disti_drinks = DistiInventory.where(distributor_id: row[8]).destroy_all
      end
      
      # first find if the drink is already loaded in our DB
      # get all drinks from this maker
      @maker_drinks = Beer.where(brewery_id: row[2])
      # loop through each drink to see if it matches this one
      @recognized_drink = nil
      @drink_name_match = false
      @maker_drinks.each do |drink|
        # check if beer name matches 
        if drink.beer_name == row[3]
           @drink_name_match = true
        else
          @alt_drink_name = AltBeerName.where(beer_id: drink.id, name: row[3])[0]
          if !@alt_drink_name.nil?
            @drink_name_match = true
          end
        end
        if @drink_name_match == true
          @recognized_drink = drink
        end
        # break this loop as soon as there is a match on this current beer's name
        break if !@recognized_drink.nil?
      end # end loop of checking drink names
      # indicate drink_id or create a new drink_id
      if !@recognized_drink.nil?
        @drink_id = @recognized_drink.id
        @drink_formats = BeerFormat.where(beer_id: @recognized_drink.id)
        if !@drink_formats.blank?
          if @drink_formats.map{|a| a.size_format_id}.exclude? row[5]
            BeerFormat.create(beer_id: @recognized_drink.id, size_format_id: row[5])
          end
        else
          BeerFormat.create(beer_id: @recognized_drink.id, size_format_id: row[5])
        end
      else
        @new_drink = Beer.create(beer_name: row[3], brewery_id: row[2], vetted: true)
        @drink_id = @new_drink.id
      end
      # now create new Disti Inventory row
      DistiInventory.create(beer_id: @drink_id, size_format_id: row[5], drink_cost: row[6], drink_price: row[7], 
                            distributor_id: row[8], disti_item_number: row[0], disti_upc: row[10], 
                            min_quantity: row[11], regular_case_cost: row[12], current_case_cost: row[13])                   
    end # end of loop through CSV data

  end # end of import method

  
end
