require 'http'

# Returns details of an activity
class GetActivityDetails
  def initialize(config)
    @config = config
  end

  def call(activity_id:, auth_token:)
    response = HTTP.auth("Bearer #{auth_token}")
                   .get("#{@config.API_URL}/activity/#{activity_id}")
    response.code == 200 ? response : nil
  end
end
