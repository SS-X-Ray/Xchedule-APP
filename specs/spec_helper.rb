# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/rg'
require 'rack/test'

require './init.rb'

def app
  XcheduleApp
end

API_URL = app.config['API_URL'].freeze
