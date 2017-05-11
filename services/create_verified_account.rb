require 'http'

class CreateVerifiedAccount
  def initialize(config)
    @config = config
  end

  def call(username:, email:, password:)
    response = HTTP.post("#{@config.API_URL}/accounts/",
                         json: { username: username,
                                 email: email,
                                 password: password })
    response.code == 201 ? true : false
  end
end
