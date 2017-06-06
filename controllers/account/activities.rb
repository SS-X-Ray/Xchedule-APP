require 'sinatra'

# Base class for Xchedule Web Application
class XcheduleApp < Sinatra::Base
  get '/account/:username/activities/?' do
    if current_account?(params)
      @activities = GetAllActivities.new(settings.config)
                                    .call(current_account: @current_account,
                                          auth_token: @auth_token)
    end

    # @activities ? slim(:activities_all) : redirect('/accounts/login')
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
                                             activity_name: activity_name,
                                             activity_location: activity_location)
        flash[:notice] = 'Your new activity has been created!'
        halt 500 if response.code != 200

        accounts = AddParticipantToActivity.new(settings.config)
                                           .call(participants: participants,
                                                 activity_id: activity_id,
                                                 auth_token: session[:auth_token])
        flash[:notice] = 'Participant added to activity!'
        halt 500 if response.code != 200

        @possible_time = CalMatching.compare({duration_hash: duration_hash, limitation_hash: limitation_hash, activity_length: activity_length, accounts: accounts})
      rescue => e
        flash[:error] = 'Something went wrong -- we will look into it!'
        logger.error "NEW_ACTIVITY FAIL: #{e}"
        redirect "/account/#{@current_account['username']}/activities"
      end
    end
  end
end
