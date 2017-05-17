# frozen_string_literal: true

require 'http'

# Returns an authenticated user, or nil
class FindAuthenticatedAccount
  def initialize(config)
    @config = config
  end

  def call(email:, password:)
    response = HTTP.post("#{@config.API_URL}/account/authenticate",
                         json: { email: email, password: password })
    response.code == 200 ? response.parse : nil
  end
end
