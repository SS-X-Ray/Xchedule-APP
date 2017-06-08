require 'http'

# Returns an authenticated user, or nil
class FindAuthenticatedGoogleAccount
  def initialize(config)
    @config = config
  end

  def call(code)
    access_token = get_access_token(code)
    get_sso_account_from_api(access_token)
  end

  def get_access_token(code)
    res = HTTP.headers(accept: 'application/json')
        .post('https://www.googleapis.com/oauth2/v4/token',
              form: { client_id: @config.GOOGLE_CLIENT_ID,
                      client_secret: @config.GOOGLE_CLIENT_SECRET,
                      grant_type: 'authorization_code',
                      redirect_uri: "#{@config.APP_URL}/google_callback",
                      code: code })
        .parse['access_token']
    ###
    puts res
    ###
    res
  end

  def get_sso_account_from_api(access_token)
    response = HTTP.headers(accept: 'application/json')
                   .get("#{@config.API_URL}/google_account?access_token=#{access_token}")
    puts "SSO: #{response.parse}"
    response.code == 200 ? response.parse : nil
  end
end
