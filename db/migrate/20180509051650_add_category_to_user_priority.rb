class AddCategoryToUserPriority < ActiveRecord::Migration[5.1]
  def change
    add_column :user_priorities, :category, :string
  end
end
