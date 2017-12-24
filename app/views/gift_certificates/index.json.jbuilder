json.array!(@gift_certificates) do |gift_certificate|
  json.extract! gift_certificate, :id, :giver_name, :giver_email, :receiver_email, :amount, :redeem_code
  json.url gift_certificate_url(gift_certificate, format: :json)
end
