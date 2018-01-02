require 'test_helper'

class GiftCertificatesControllerTest < ActionController::TestCase
  setup do
    @gift_certificate = gift_certificates(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:gift_certificates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create gift_certificate" do
    assert_difference('GiftCertificate.count') do
      post :create, gift_certificate: { amount: @gift_certificate.amount, giver_email: @gift_certificate.giver_email, giver_name: @gift_certificate.giver_name, receiver_email: @gift_certificate.receiver_email, redeem_code: @gift_certificate.redeem_code }
    end

    assert_redirected_to gift_certificate_path(assigns(:gift_certificate))
  end

  test "should show gift_certificate" do
    get :show, id: @gift_certificate
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @gift_certificate
    assert_response :success
  end

  test "should update gift_certificate" do
    patch :update, id: @gift_certificate, gift_certificate: { amount: @gift_certificate.amount, giver_email: @gift_certificate.giver_email, giver_name: @gift_certificate.giver_name, receiver_email: @gift_certificate.receiver_email, redeem_code: @gift_certificate.redeem_code }
    assert_redirected_to gift_certificate_path(assigns(:gift_certificate))
  end

  test "should destroy gift_certificate" do
    assert_difference('GiftCertificate.count', -1) do
      delete :destroy, id: @gift_certificate
    end

    assert_redirected_to gift_certificates_path
  end
end
