# == Schema Information
#
# Table name: user_style_preferences
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  beer_style_id   :integer
#  user_preference :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class UserStylePreference < ApplicationRecord
  belongs_to :user
  belongs_to :beer_style
  
  def self.number_of_master_styles(user_id)
    @all_user_styles = UserStylePreference.where(user_id: user_id, user_preference: "like")
    
    @master_styles = Array.new
    @all_user_styles.each do |style|
      @this_master_style = style.beer_style.master_style_id
      @master_styles << @this_master_style
    end
    
    @master_styles = @master_styles.uniq
   
    @final_count = @master_styles.count
    #Rails.logger.debug("Final count: #{@final_count.inspect}")
    return @final_count
  end # end of number_of_master_styles method
  
end # end of class