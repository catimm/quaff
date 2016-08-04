class AddFirstNameAndZipCodeAndCityAndStateAndDeliveryOkToInvitationRequest < ActiveRecord::Migration
  def change
    add_column :invitation_requests, :first_name, :string
    add_column :invitation_requests, :zip_code, :string
    add_column :invitation_requests, :city, :string
    add_column :invitation_requests, :state, :string
    add_column :invitation_requests, :delivery_ok, :boolean
  end
end
