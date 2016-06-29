class AddSignupBeerAndSignupCiderAndSignupBeerCiderToBeerStyle < ActiveRecord::Migration
  def change
    add_column :beer_styles, :signup_beer, :boolean
    add_column :beer_styles, :signup_cider, :boolean
    add_column :beer_styles, :signup_beer_cider, :boolean
  end
end
