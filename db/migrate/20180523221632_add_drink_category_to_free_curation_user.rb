class AddDrinkCategoryToFreeCurationUser < ActiveRecord::Migration[5.1]
  def change
    add_column :free_curation_users, :drink_category, :string
  end
end
