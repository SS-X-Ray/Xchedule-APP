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
      redirect '/'
    else
      flash[:error] = 'Your username or password did not match our records'
      redirect '/account/login/'
    end
  end

  get '/account/logout/?' do
    @current_account = nil
    SecureSession.new(session).delete(:current_account)
    flash[:notice] = 'You have logged out - please login again to use this site'
    redirect '/account/login'
  end

  get '/google_callback/?' do
    begin
      sso_account = FindAuthenticatedGoogleAccount.new(settings.config)
                                                  .call(params['code'])
      authenticate_login(sso_account)
      # redirect "/account/#{@current_account['username']}/projects"
      # 還沒寫
      redirect '/'
    rescue => e
      flash[:error] = 'Could not sign in using Github'
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
end
