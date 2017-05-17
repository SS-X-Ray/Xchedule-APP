# frozen_string_literal: true
require_relative '../lib/init.rb'
require 'econfig'
require 'sinatra'
require 'rack-flash'
require 'rack/ssl-enforcer'
require 'rack/session/redis'

# Base class for ConfigShare Web Application
class XcheduleApp < Sinatra::Base
  extend Econfig::Shortcut

  ONE_MONTH = 2_592_000 # One month in seconds

  set :views, File.expand_path('../../views', __FILE__)
  set :public_dir, File.expand_path('../../public', __FILE__)

  configure :production do
    use Rack::SslEnforcer
  end

  configure do
    Econfig.env = settings.environment.to_s
    Econfig.root = File.expand_path('..', settings.root)

    SecureMessage.setup(settings.config)
    SecureSession.setup(settings.config)
  end
  # use Rack::Session::Cookie, expire_after: ONE_MONTH
  # use Rack::Session::Redis, expire_after: ONE_MONTH, redis_server: settings.config.REDIS_URL
  configure :development, :test do
    use Rack::Session::Pool, expire_after: ONE_MONTH
  end

  configure :production do
    use Rack::Session::Redis, expire_after: ONE_MONTH, redis_server: settings.config.REDIS_URL
  end
  use Rack::Flash

  def current_account?(params)
    @current_account && @current_account['username'] == params[:username]
  end

  def halt_if_incorrect_user(params)
    return true if current_account?(params)
    flash[:error] = 'You used the wrong account for this request'
    redirect '/account/login'
    halt
  end

  before do
    @current_account = session[:current_account]
    @auth_token = SecureSession.new(session).get(:auth_token)
  end

  get '/' do
    slim :home
  end
end
