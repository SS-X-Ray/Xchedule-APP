# frozen_string_literal: true

folders = 'lib,config,services,forms,controllers'
Dir.glob("./{#{folders}}/init.rb").each do |file|
  require file
end
