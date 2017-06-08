require 'sinatra'

# Base class for Xchedule Web Application
class XcheduleApp < Sinatra::Base
  get '/account/:username/activities/?' do
    if current_account?(params)
      @activities = GetAllActivities.new(settings.config)
                                    .call(current_account: @current_account,
                                          auth_token: @auth_token)
      puts @activites
    end
    @config = settings.config
    slim :activity_list
  end

  get '/account/:username/activities/:activity_id/?' do
    if current_account?(params)
      @activities = GetActivityDetails.new(settings.config)
                                      .call(activity_id: params[:activity_id],
                                             auth_token: @auth_token)
      if @activities
        # slim(:project)
      else
        flash[:error] = 'We cannot find this activity in your account'
        redirect "/account/#{params[:username]}/activities"
      end
    else
      redirect '/login'
    end
  end

  post '/account/:username/activities/:activity_id/participant/?' do
    halt_if_incorrect_user(params)

    participant = AddParticipantToActivity.call(
      participant_emails: params[:participant_emails],
      activity_id: params[:activity_id],
      auth_token: session[:auth_token])

    if participant
      account_info = "#{participant['username']} (#{participant['email']})"
      flash[:notice] = "Added #{account_info} to the activity"
    else
      flash[:error] = "Could not add #{params['email']} to the activity"
    end

    redirect back
  end

  post '/account/:username/activities/?' do
    halt_if_incorrect_user(params)
    # puts 123
    # puts params[:activity_name]
    # puts params[:participants]
    # puts params[:activity_location]
    # puts params[:duration_from]
    # puts params[:duration_to]
    # puts params[:activity_length]
    # puts params[:limitation_before]
    # puts params[:limitation_after]
    # puts 123
    activities_url = "/account/#{@current_account['username']}/activities"

    new_activity_data = NewActivity.call(params)
    if new_activity_data.failure?
      flash[:error] = new_activity_data.messages.values.join('; ')
      redirect activities_url
    else
      begin

        activity_id = CreateNewActivity.new(settings.config)
                                       .call(auth_token: session[:auth_token],
                                             owner_id: @current_account['id'],
                                             activity_name: params[:activity_name],
                                             activity_location: params[:activity_location])
        flash[:notice] = 'Your new activity has been created!'
        puts 1
        halt 500 if activity_id.nil?
        puts 2
        duration_hash = {start: params[:duration_from], end: params[:duration_to]}
        puts duration_hash
        limitation_hash = {up: parse_time_2_float(params[:limitation_before]),
                           low: parse_time_2_float(params[:limitation_after])}
        puts limitation_hash
        puts params[:participants]
        puts 5
        puts params[:participants].class
        puts 6
        puts activity_id
        puts 7
        puts session[:auth_token]
        puts 8
        puts duration_hash
        puts 9
        participants = params[:participants].split(',')
        puts 9.1
        puts participants
        puts participants.class
        accounts = AddParticipantToActivity.new(settings.config)
                                           .call(participants: participants,
                                                 activity_id: activity_id,
                                                 auth_token: session[:auth_token],
                                                 duration_hash: duration_hash)
        halt 500 if accounts.empty?
        puts 10
        puts accounts
        puts 11
        owner_freebusy = GetFreeBusy.call(@current_account['access_token'], duration_hash)
        puts owner_freebusy
        puts 12
        accounts << CalAccount.new(owner_freebusy)
        puts accounts
        puts 13
        flash[:notice] = 'Participant added to activity!'
        puts 14
        possible_time = CalMatching.compare({duration_hash: duration_hash,
                                              limitation_hash: limitation_hash,
                                              activity_length: params[:activity_length].to_i,
                                              accounts: accounts})
puts possible_time
        if possible_time.success?
          @possible_time = possible_time.value
        else
          halt 500
        end
        puts 15
        HTTP.patch("#{settings.config.API_URL}/activity", json: {update_data:{activity_id: activity_id, possible_time: @possible_time.to_json}})
      rescue => e
        flash[:error] = 'Something went wrong -- we will look into it!'
        logger.error "NEW_ACTIVITY FAIL: #{e}"
      end
      redirect "/account/#{@current_account['username']}/activities"
    end
  end

  def parse_time_2_float(time)
    Time.parse(time).hour.to_f + Time.parse(time).min/60.to_f
  end
end
