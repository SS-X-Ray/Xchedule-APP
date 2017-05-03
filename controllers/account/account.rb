# frozen_string_literal: true

require 'sinatra'

# Account related routes
class XcheduleApp < Sinatra::Base
  get '/account/login/?' do
    slim :login
  end

  post '/account/login/?' do
    puts "CREDENTIALS: #{params[:email]} - #{params[:password]}"
    @current_account = FindAuthenticatedAccount.new(settings.config).call(
      email: params[:email], password: params[:password]
    )

    if @current_account
      session[:current_account] = @current_account
      flash[:error] = "Welcome back #{@current_account['username']}"
      slim :home
    else
      flash[:error] = 'Your email or password did not match our records'
      slim :login
    end
  end

  get '/account/logout/?' do
    @current_account = nil
    session[:current_account] = nil
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
