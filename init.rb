# frozen_string_literal: true

folders = 'lib,config,services,controllers,forms'
Dir.glob("./{#{folders}}/init.rb").each do |file|
  require file
end
