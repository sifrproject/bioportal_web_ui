source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.1'

gem 'sass-rails', '~> 5.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'uglifier', '>= 4.2.0'

# Uncomment this line to compile assets on the CentOS server (it needs a java runtime)
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# gem 'duktape'

gem 'jquery-ui-rails'
gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# To use debugger
# gem 'debugger'

gem "pry"
gem "iconv"
gem "hpricot", "~> 0.8.6"
gem "recaptcha", "= 0.4.0"
gem "rest-client", "~> 1.8.0"
gem "mysql", "~> 2.9.1"
gem "i18n", "~> 0"
gem "haml", "~> 4.0.0"
gem "will_paginate", "~> 3.0"
gem "rdoc"
gem "rack-mini-profiler"
gem "flamegraph"
gem "stackprof", :require => false
gem 'cube-ruby', require: 'cube'
gem 'oj'
gem 'multi_json'
gem 'rails_autolink'
gem 'dalli'
gem 'thin'

# application monitoring
gem 'newrelic_rpm'

gem 'ontologies_api_client', :git => "https://github.com/sifrproject/ontologies_api_ruby_client.git", branch: "lirmm"

group :staging, :production do
  #logs in json format, useful for shipping logs to logstash
  gem 'rackstash', git: "https://github.com/planio-gmbh/rackstash.git"
  gem 'logstash-logger'
end

group :development do
    #Capistrano
    gem 'capistrano', '~> 3.4.1', require: false
    # rails specific capistrano funcitons
    gem 'capistrano-rails', '~> 1.1.0', require: false
    # integrate bundler with capistrano
    gem 'capistrano-bundler', require: false
    # passenger reload
    gem 'capistrano-passenger', require: false
end
