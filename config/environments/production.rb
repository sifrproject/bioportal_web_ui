# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false


memcache_options = {
  :c_threshold => 10_000,
  :compression => true,
  :debug => false,
  :namespace => 'BioPortal',
  :readonly => false,
  :urlencode => true
}

require 'memcache' 
CACHE = MemCache.new memcache_options
CACHE.servers = 'localhost:11211'

ActionController::Base.session_options[:cache] = CACHE
# end memcache setup

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked # We're in smart spawning mode, se we need to reset connections to stuff when forked
      CACHE.reset # reset memcache connection
    else # We're in conservative spawning mode. We don't need to do anything.
    end
  end
end