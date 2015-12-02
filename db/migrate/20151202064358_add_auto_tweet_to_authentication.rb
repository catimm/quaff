class AddAutoTweetToAuthentication < ActiveRecord::Migration
  def change
    add_column :authentications, :auto_tweet, :Boolean
  end
end
