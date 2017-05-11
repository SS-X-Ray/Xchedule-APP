# frozen_string_literal: true

# require 'sinatra'
#
# configure :development do
#   def reload!
#     # Tux reloading tip: https://github.com/cldwalker/tux/issues/3
#     exec $PROGRAM_NAME, *ARGV
#   end
# end

require 'sinatra'

configure :development, :test do
  require 'fakeredis'
  def reload!
    # Tux reloading tip: https://github.com/cldwalker/tux/issues/3
    exec $PROGRAM_NAME, *ARGV
  end
end

configure :production do
  require 'redis'
end
