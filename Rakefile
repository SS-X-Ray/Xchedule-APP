# frozen_string_literal: true

require 'rake/testtask'
require './init.rb'

task default: [:rubocop, :spec]

desc 'Run all the tests'
Rake::TestTask.new(:spec) do |t|
  t.pattern = 'specs/*_spec.rb'
  t.warning = false
end

desc 'Rake all the Ruby'
task :rubocop do
  `rubopcop **/*.rb`
end

task :run do
  sh 'rerun "rackup -p 9595"'
end
