class AddUserReviewedToFreeCurationUser < ActiveRecord::Migration[5.1]
  def change
    add_column :free_curation_users, :user_reviewed, :boolean
  end
end
