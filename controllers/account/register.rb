# account registration
class XcheduleApp < Sinatra::Base
  get '/account/register/?' do
    slim :register
  end

  post '/account/register/?' do
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

  get '/account/register/:token_secure/verify' do
    @token_secure = params[:token_secure]
    @new_account = SecureMessage.decrypt(@token_secure)
    slim :register_confirm
  end

  post '/account/register/:token_secure/verify' do
    redirect "/register/#{params[:token_secure]}/verify" if
      (params[:password] != params[:password_confirm]) ||
      params[:password].empty?

    new_account = SecureMessage.decrypt(params[:token_secure])
    result = CreateVerifiedAccount.new(settings.config).call(
      username: new_account['username'],
      email: new_account['email'],
      password: params['password']
    )

    if result
      flash[:notice] = 'Please login with your new username and password'
      redirect '/account/login'
    else
      flash[:error] = 'Your account could not be created. Please try again'
      redirect '/account/register'
    end
  end
end
