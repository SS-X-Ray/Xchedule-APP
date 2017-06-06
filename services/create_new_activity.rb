require 'http'

# Create New Activity with organizer_id, name, location(optional)
class CreateNewActivity
  def initialize(config)
    @config = config
  end

  def call(auth_token:, owner_id:, activity_name:, activity_location:)
    response = HTTP.auth("Bearer #{auth_token}")
                   .post("#{@config.API_URL}/accounts/#{owner_id}/organized_activities/?",
                         json: { organizer_id: owner_id, name: activity_name,
                                 location: activity_location })
    response.parse['activity_id']
  end
end
