require 'http'

# Returns all activities belonging to an account
class GetAllActivities
  def initialize(config)
    @config = config
  end

  def call(current_account:, auth_token:)
    response = HTTP.auth("Bearer #{auth_token}")
                   .get("#{@config.API_URL}/accounts/#{current_account['id']}/activities")
    response.code == 200 ? extract_activities(response.parse) : nil
  end

  private

  def extract_activities(activities)
    activities['data'].map do |acti|
      { id: acti['id'],
        name: acti['attributes']['name'],
        possible_time: acti['attributes']['possible_time'],
        result_time: acti['attributes']['result_time'],
        location: acti['attributes']['location'],
        organizer: acti['relationships']['organizer'] }
    end
  end
end
