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
                puts 1.1
      puts res.body
      access_token = GetParticipantAccessToken.new(@config).call(participant_id)
      puts 2.1
      puts access_token
      participant_freebusy = GetFreeBusy.call(access_token, duration_hash)
      puts 3.1
      puts participant_freebusy
      CalAccount.new(participant_freebusy)
    end
  end
end
