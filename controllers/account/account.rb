# frozen_string_literal: true

require 'sinatra'

# Account related routes
class XcheduleApp < Sinatra::Base
  def authenticate_login(auth)
    @current_account = auth['account']
    @auth_token = auth['auth_token']
    current_session = SecureSession.new(session)
    current_session.set(:current_account, @current_account)
    current_session.set(:auth_token, @auth_token)
  end

  def google_sso_url
    url = 'https://accounts.google.com/o/oauth2/v2/auth'
    scope = 'https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email '
    params = ["client_id=#{settings.config.GOOGLE_CLIENT_ID}",
              "redirect_uri=#{settings.config.APP_URL}/google_callback",
              'response_type=code',
              "scope=#{scope}"]
    "#{url}?#{params.join('&')}"
  end


  get '/account/login/?' do
    @google_url = google_sso_url
    slim :login
  end

  post '/account/login/?' do
    credentials = LoginCredentials.call(params)

    if credentials.failure?
      flash[:error] = 'Please enter both username and password'
      redirect '/account/login'
    end

    auth = FindAuthenticatedAccount.new(settings.config)
                                   .call(credentials)

    if auth
      authenticate_login(auth)
      flash[:notice] = "Welcome back #{@current_account['username']}"
      redirect "/account/#{@current_account['username']}/activities/?"
    else
      flash[:error] = 'Your username or password did not match our records'
      redirect '/account/login/'
    end
  end

  get '/account/logout/?' do
    @current_account = nil
    SecureSession.new(session).delete(:current_account)
    SecureSession.new(session).delete(:auth_token)
    flash[:notice] = 'You have logged out - please login again to use this site'
    redirect '/account/login'
  end

  get '/google_callback/?' do
    begin
      sso_account = FindAuthenticatedGoogleAccount.new(settings.config)
                                                  .call(params['code'])
      authenticate_login(sso_account)
      flash[:notice] = "Welcome back #{@current_account['username']}"
      redirect "/account/#{@current_account['username']}/activities/?"
    rescue => e
      flash[:error] = 'Could not sign in using Google'
      puts "RESCUE: #{e}"
      redirect 'account/login'
    end
  end

  def get_access_token(code)
    HTTP.headers(accept: 'application/json')
        .post('https://www.googleapis.com/oauth2/v4/token',
              form: { client_id: settings.config.GOOGLE_CLIENT_ID,
                      client_secret: settings.config.GOOGLE_CLIENT_SECRET,
                      grant_type: 'authorization_code',
                      redirect_uri: "#{settings.config.APP_URL}/register_callback",
                      code: code })
        .parse['access_token']
  end

  get '/register_callback/?' do
    begin
      current_account = SecureSession.new(session).get(:current_account)
      email = current_account['email']
      access_token = get_access_token(params['code'])
      response = HTTP.patch("#{settings.config.API_URL}/account/access_token/",
                           json: { email: email,
                                   access_token: access_token })
      if response
        flash[:notice] = 'Please login with your new username and password'
        redirect '/account/login'
      else
        flash[:error] = 'Your account could not be created. Please try again'
        redirect '/account/register'
      end
    rescue => e
      flash[:error] = 'Could not set access_token to account'
      puts "RESCUE: #{e}"
      redirect 'account/login'
    end
  end

  get '/account/register/?' do
    slim(:register)
  end

  get '/account/:username/?' do
    halt_if_incorrect_user(params)
    slim(:account)
  end

  # Find username by email
  get '/account/parse/:email' do
    response = HTTP.get("#{settings.config.API_URL}/account/parse/#{params['email']}")
    if response.code == 200
      puts response
      JSON.pretty_generate(id: response.parse['id'], username: response.parse['username'])
    else
      halt 400
      flash[:error] = 'Cannot find account by email'
    end
  end
end
