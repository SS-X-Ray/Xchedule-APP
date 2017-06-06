# account registration
require 'sinatra'

class XcheduleApp < Sinatra::Base
  get '/account/register/?' do
    slim :register
  end

  # Page register
  post '/account/register/?' do
    registration = Registration.call(params)
    if registration.failure?
      flash[:error] = 'Please enter a valid username and email'
      redirect 'account/register'
      halt
    end

    begin
      EmailRegistrationVerification.new(settings.config)
                                   .call(username: params[:username],
                                         email: params[:email])
      flash[:notice] = 'A verification email has been sent to you.'
      redirect '/'
    rescue => e
      logger.error "FAIL EMAIL: #{e}"
      flash[:error] = 'Unable to send email verification'
      redirect '/account/register'
    end
  end

  # Register confirm
  get '/account/register/:token_secure/verify' do
    @token_secure = params[:token_secure]
    @new_account = SecureMessage.decrypt(@token_secure)
    slim :register_confirm
  end

  # Post register account
  post '/account/register/:token_secure/verify' do
    passwords = Passwords.call(params)
    if passwords.failure?
      flash[:error] = passwords.messages.values.join('; ')
      redirect "/account/register/#{params[:token_secure]}/verify"
      halt
    end

    new_account = SecureMessage.decrypt(params[:token_secure])
    result = CreateVerifiedAccount.new(settings.config).call(
      username: new_account['username'],
      email: new_account['email'],
      password: passwords[:password]
    )

    if result
      flash[:notice] = 'Please login with your new username and password'
      # redirect '/account/login'
    else
      flash[:error] = 'Your account could not be created. Please try again'
      # redirect '/account/register'
    end

    pararms = { email: new_account['email'], password: passwords[:password] }
    auth = FindAuthenticatedAccount.new(settings.config)
                                   .call(pararms)
    if auth
      authenticate_login(auth)
    else
      flash[:error] = 'Your username or password did not match our records'
    end
    url = google_register_url
    redirect url
  end

  def google_register_url
    url = 'https://accounts.google.com/o/oauth2/v2/auth'
    scope = 'https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email '
    params = ["client_id=#{settings.config.GOOGLE_CLIENT_ID}",
              "redirect_uri=#{settings.config.APP_URL}/register_callback",
              'response_type=code',
              "scope=#{scope}"]
    "#{url}?#{params.join('&')}"
  end
end
