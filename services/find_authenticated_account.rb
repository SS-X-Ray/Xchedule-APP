# frozen_string_literal: true

require 'http'

# Returns an authenticated user, or nil
class FindAuthenticatedAccount
  def initialize(config)
    @config = config
  end

  def call(username:, password:)
    response = HTTP.post("#{@config.API_URL}/accounts/authenticate",
                         json: { username: username, password: password })
    response.code == 200 ? response.parse['account'] : nil
  end
end
