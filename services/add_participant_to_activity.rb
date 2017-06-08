require 'http'

class AddParticipantToActivity
  def initialize(config)
    @config = config
  end

  def call(participants:, activity_id:, auth_token:, duration_hash:)
    participants.map do |participant_id|
      res = HTTP.auth("Bearer #{auth_token}")
          .post("#{@config.API_URL}/activity/participant/",
                json: { participant_id: participant_id, activity_id: activity_id})
      access_token = GetParticipantAccessToken.new(@config).call(participant_id)
      participant_freebusy = GetFreeBusy.call(access_token, duration_hash)
      CalAccount.new(participant_freebusy)
    end
  end
end
