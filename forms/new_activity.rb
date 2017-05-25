# frozen_string_literal: true

require 'dry-validation'

NewActivity = Dry::Validation.Form do
  required(:name).filled
  required(:duration).filled
  required(:activity_length).filled
  optional(:limitation)
  optional(:location)

  configure do
    config.messages_file = File.join(__dir__, 'new_activity_errors.yml')
  end
end
