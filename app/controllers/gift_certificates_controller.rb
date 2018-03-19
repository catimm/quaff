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
      @user_email = current_user.email
      @gift_certificate.giver_name = current_user.first_name + " " + current_user.last_name
      @gift_certificate.giver_email = current_user.email
    else
      @user_email = ""
    end
    # set form values
    @data_description = "$50 - Knird Gift Certificate"
    @credit_value = 50
    
    @logged_in = current_user
  end
  
  def process_credit_form_changes
    @data = params[:id]
    @data_split = @data.split("-")
    @credit_amount = @data_split[0]
    @email = @data_split[1]
    
  if !@credit_amount.nil?
      # set form values
      if @credit_amount == "25"
        @data_description = "$25 - Knird Gift Certificate"
        @credit_value = 25
      elsif @credit_amount == "50"
        @data_description = "$50 - Knird Gift Certificate"
        @credit_value = 50
      elsif @credit_amount == "100"
        @data_description = "$100 - Knird Gift Certificate"
        @credit_value = 100
      else
        @data_description = "$" + @credit_amount + " - Knird Gift Certificate"
        @credit_value = @credit_amount.to_i
      end
    end
    
    
    # update checkout button
    respond_to do |format|
      format.js
    end # end of redirect to jquery
    
  end # end of process_credit_form_changes method
  
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

    if !@gift_certificate.valid?
        if @gift_certificate.giver_name.nil?
          flash[:failure] = "Please provide your name"
        elsif @gift_certificate.giver_email.nil?
          flash[:failure] = "Please provide your email"
        elsif @gift_certificate.receiver_name.nil?
          flash[:failure] = "Please include the recipient's name"
        elsif @gift_certificate.receiver_email.nil?
          flash[:failure] = "Please include the recipient's email"
        elsif @gift_certificate.amount.nil?
          flash[:failure] = "Please choose an amount"
        end
        redirect_to gift_certificates_new_path()
        return
    else
      token = params[:stripeToken]
      @total_amount = (gift_certificate_params[:amount].to_f * 100).floor
  
      # Create the gift certificate with purchase completed as false
      # will be set to true by the callback from stripe
      @gift_certificate.purchase_completed = false
      coupon_code = generate_unique_coupon_code()
      if coupon_code == nil
        # Return error
        flash[:failure] = "A gift certificate could not be created and your credit card has not been charged. Please try again later."
        redirect_to gift_certificates_new_path()
        return
      end
  
      @gift_certificate.redeem_code = coupon_code
      @gift_certificate.save
      
      # check for stripe customer number
      if user_signed_in?
        # check if user already has a subscription row
        @current_customer = UserSubscription.where(account_id: current_user.account_id, currently_active: true).where("stripe_customer_number IS NOT NULL").first
        
        if !@current_customer.blank?
          # charge the customer for their subscription 
          Stripe::Charge.create(
            :amount => @total_amount, # in cents
            :currency => "usd",
            :customer => @current_customer.stripe_customer_number,
            :description => "Knird Gift Certificate for #{@gift_certificate.receiver_email}",
            :metadata => {"redeem_code" => @gift_certificate.redeem_code}
          )
        else 
          # create Stripe customer acct
          customer = Stripe::Customer.create(
                  :source => params[:stripeToken],
                  :email => current_user.email
                )
          # charge the customer for their subscription 
          Stripe::Charge.create(
            :amount => @total_amount, # in cents
            :currency => "usd",
            :customer => customer.id,
            :description => "Knird Gift Certificate for #{@gift_certificate.receiver_email}",
            :metadata => {"redeem_code" => @gift_certificate.redeem_code}
          )
        end
           
     
      else
        # create Stripe customer acct
          customer = Stripe::Customer.create(
                  :source => params[:stripeToken],
                  :email => @gift_certificate.giver_email
                )
        # charge the customer for their subscription 
          Stripe::Charge.create(
            :amount => @total_amount, # in cents
            :currency => "usd",
            :customer => customer.id,
            :description => "Knird Gift Certificate for #{@gift_certificate.receiver_email}",
            :metadata => {"redeem_code" => @gift_certificate.redeem_code}
          )
      end
    end # end of check whether form is valid
    
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
