# frozen_string_literal: true
require 'sinatra'

configure :development, :test do
  require 'fakeredis'
  def reload!
    exec $PROGRAM_NAME, *ARGV
  end
end

configure :production do
  require 'redis'
end
