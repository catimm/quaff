class AddSharedAtToFreeCuration < ActiveRecord::Migration[5.1]
  def change
    add_column :free_curations, :shared_at, :datetime
  end
end
