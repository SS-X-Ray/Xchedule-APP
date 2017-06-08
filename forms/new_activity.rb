# frozen_string_literal: true

require 'dry-validation'

NewActivity = Dry::Validation.Form do
  required(:activity_name).filled
  required(:participants).filled
  optional(:activity_location)
  required(:duration_from).filled
  required(:duration_to).filled
  required(:activity_length).filled
  optional(:limitation_before)
  optional(:limitation_after)

  configure do
    config.messages_file = File.join(__dir__, 'new_activity_errors.yml')
  end
end
