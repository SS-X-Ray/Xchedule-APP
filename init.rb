# frozen_string_literal: true

folders = 'lib,config,values,services,forms,controllers'
Dir.glob("./{#{folders}}/init.rb").each do |file|
  require file
end
