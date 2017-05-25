# frozen_string_literal: true

require 'dry-validation'

USERNAME_REGEX = /^[a-zA-Z0-9]+([._]?[a-zA-Z0-9]+)*$/
EMAIL_REGEX = /@/

LoginCredentials = Dry::Validation.Form do
  required(:email).filled
  required(:password).filled
end

Registration = Dry::Validation.Form do
  # required(:username).filled(format?: USERNAME_REGEX)
  # required(:email).filled(format?: EMAIL_REGEX)
  required(:email).filled(format?: EMAIL_REGEX)
  required(:password).filled
end

Passwords = Dry::Validation.Form do
  configure do
    config.messages_file = File.join(__dir__, 'password_errors.yml')

    def enough_entropy?(string)
      StringSecurity.entropy(string) >= 3.0
    end
  end

  required(:password).filled
  required(:password_confirm).filled

  rule(password_entropy: [:password]) do |password|
    password.enough_entropy?
  end

  rule(passwords_match: [:password, :password_confirm]) do |pass1, pass2|
    pass1.eql?(pass2)
  end
end
