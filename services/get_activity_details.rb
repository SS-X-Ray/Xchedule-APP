require 'http'

# Returns details of an activity
class GetActivityDetails
  def initialize(config)
    @config = config
  end

  def call(activity_id:, auth_token:)
    response = HTTP.auth("Bearer #{auth_token}")
                   .get("#{@config.API_URL}/activities/#{activity_id}")
    response.code == 200 ? extract_activity_details(response.parse) : nil
  end

  private

  def extract_activity_details(activity_data)
    { name: activity_data['attributes']['name'],
      location: activity_data['attributes']['location'],
      possible_time: activity_data['attributes']['possible_time'],
      result_time: activity_data['attributes']['result_time'],
      organizer: activity_data['relationships']['organizer'],
      participants: activity_data['relationships']['participants'] }
  end
end
