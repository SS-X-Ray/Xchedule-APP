require 'http'

class GetParticipantAccessToken
  def initialize(config)
    @config = config
  end

  def call(participant_id)
    response = HTTP.get("#{@config.API_URL}/account/#{participant_id}")
    response.parse['data']['access_token']
  end
end
