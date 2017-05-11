# frozen_string_literal: true

require 'sinatra'

# Account related routes
class XcheduleApp < Sinatra::Base
  get '/account/login/?' do
    slim :login
  end

  post '/account/login/?' do
    @current_account = FindAuthenticatedAccount.new(settings.config).call(
      username: params[:username], password: params[:password]
    )

    if @current_account
      SecureSession.new(session).set(:current_account, @current_account)
      puts "SESSION: #{session[:current_account]}"
      flash[:notice] = "Welcome back #{@current_account['username']}"
      redirect '/'
    else
      flash[:error] = 'Your username or password did not match our records'
      slim :login
    end
  end

  get '/account/logout/?' do
    @current_account = nil
    SecureSession.new(session).delete(:current_account)
    flash[:notice] = 'You have logged out - please login again to use this site'
    slim :login
  end

  get '/account/register/?' do
    slim(:register)
  end

  get '/account/:username/?' do
    if @current_account && @current_account['username'] == params[:username]
      slim(:account)
    else
      redirect '/account/login'
    end
  end
end
