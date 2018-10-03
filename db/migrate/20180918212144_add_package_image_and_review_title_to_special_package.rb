class AddPackageImageAndReviewTitleToSpecialPackage < ActiveRecord::Migration[5.1]
  def change
    add_column :special_packages, :package_image, :string
    add_column :special_packages, :review_title, :string
  end
end
