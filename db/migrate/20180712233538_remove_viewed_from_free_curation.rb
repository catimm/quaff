class RemoveViewedFromFreeCuration < ActiveRecord::Migration[5.1]
  def change
    remove_column :free_curations, :viewed, :boolean
  end
end
