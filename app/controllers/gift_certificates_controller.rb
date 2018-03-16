class GiftCertificatesController < ApplicationController
  require "stripe"
  require "coupon_code"
  include GiftCertificateRedeem

  def success
  end

  def index
  end

  # GET /gift_certificates/new
  def new
    @gift_certificate = GiftCertificate.new

    if user_signed_in?
        @gift_certificate.giver_name = current_user.first_name + " " + current_user.last_name
        @gift_certificate.giver_email = current_user.email
    end

    @logged_in = current_user
  end

  def redeem
      if !session[:user_return_to].nil? and session[:user_return_to].include? gift_certificates_redeem_path
          # delete the session return to prevent returning to this url after every sign-in
          session.delete(:user_return_to)
      end
  end

  def signin_and_redeem
      redeem_code = params[:redeem_code]
      session[:user_return_to] = gift_certificates_redeem_path() + "?redeem_code=#{redeem_code}"
      redirect_to new_user_session_path()
  end

  def signup_and_redeem
      redeem_code = params[:redeem_code]

      if redeem_code == nil
          # use an invalid redeem code to redirect user from signup page to redeem page
          redeem_code = "MANUAL_ENTRY"
      end

      session[:redeem_code] = redeem_code
      redirect_to new_user_path()
  end
  
  def redirect_invalid_code(redeem_code)
      flash[:failure] = "This redemption code is not valid. Please enter a valid redemption code and try again."
      redirect_to gift_certificates_redeem_path() + "?redeem_code=#{redeem_code}"
  end
    
  def process_redeem
      redeem_code = params[:redeem_code]
      if redeem_certificate(redeem_code, current_user) == false
          return redirect_invalid_code redeem_code
      end
      
      flash[:success] = "The gift certificate with code #{redeem_code} was successfully redeemed and credited to your account."
      return_path = session[:user_return_to]

      if return_path != nil
          session.delete(:user_return_to)
          redirect_to return_path
      else
          redirect_to gift_certificates_index_path()
      end
  end
  
  # POST /gift_certificates
  # POST /gift_certificates.json
  def create
    @gift_certificate = GiftCertificate.new(gift_certificate_params)

    token = params[:stripeToken]
    amount = (gift_certificate_params[:amount].to_f * 100).floor

    # Create the gift certificate with purchase completed as false
    # will be set to true by the callback from stripe
    @gift_certificate.purchase_completed = false
    coupon_code = generate_unique_coupon_code()
    if coupon_code == nil
      # Return error
      flash[:failure] = "A gift certificate could not be created and your credit card has not been charged. Please try again later."
      redirect_to gift_certificates_new_path()
    end

    @gift_certificate.redeem_code = coupon_code
    @gift_certificate.save

    # Make the stripe call after saving the gift certificate to make sure
    # that when the callback comes from stripe there is already a record in the db to update
    charge = Stripe::Charge.create(
      :amount => amount,
      :currency => "usd",
      :description => "Knird Gift Certificate for #{@gift_certificate.receiver_email}",
      :source => token,
      :metadata => {"redeem_code" => @gift_certificate.redeem_code}
    )
    
    flash[:success] = "Thank you for ordering the gift certificate. You will receive an email at #{@gift_certificate.giver_email} with the details shortly."
    redirect_to gift_certificates_success_path()
  end

  private
    def generate_unique_coupon_code
        # try 10 times to generate a unique code and quit if unsuccessful
        for i in 0..10
          new_code = CouponCode.generate(parts: 2)
          existing = GiftCertificate.find_by redeem_code: new_code
          if existing == nil
            return new_code
          end
        end
        return nil
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_gift_certificate
      @gift_certificate = GiftCertificate.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def gift_certificate_params
      params.require(:gift_certificate).permit(:giver_name, :giver_email, :receiver_name, :receiver_email, :amount, :redeem_code)
    end
end
