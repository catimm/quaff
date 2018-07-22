class AddViewedAndEmailsSentToFreeCuration < ActiveRecord::Migration[5.1]
  def change
    add_column :free_curations, :viewed, :boolean
    add_column :free_curations, :emails_sent, :integer
  end
end
