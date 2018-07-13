class AddViewedAtToFreeCuration < ActiveRecord::Migration[5.1]
  def change
    add_column :free_curations, :viewed_at, :datetime
  end
end
