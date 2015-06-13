class AddTouchedByUserToBeer < ActiveRecord::Migration
  def change
    add_column :beers, :touched_by_user, :integer
  end
end
