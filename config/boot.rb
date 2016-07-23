ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# Load file with hash and array to give URI/label of enforced attribute values
require File.expand_path('../enforced_attribute_values.rb', __FILE__)