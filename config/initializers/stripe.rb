#if Rails.env == 'production'
#  Rails.configuration.stripe = {
#    :publishable_key => ENV['STRIPE_ID'],
#    :secret_key      => ENV['STRIPE_SECRET']
#  }
#else
  Rails.configuration.stripe = {
    :publishable_key => ENV['STRIPE_TEST_ID'],
    :secret_key      => ENV['STRIPE_TEST_SECRET']
  }
#end

Stripe.api_key = Rails.configuration.stripe[:secret_key]