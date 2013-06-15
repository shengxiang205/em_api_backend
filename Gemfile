#encoding: utf-8
source 'http://ruby.taobao.org/'

gem 'rack'
gem 'rack-fiber_pool', :require => 'rack/fiber_pool'
gem 'sinatra'

gem 'sinatra-synchrony', :require => 'sinatra/synchrony'
gem 'em-synchrony', :require => ['em-synchrony']

gem 'rake'
# gem 'pony'   # pony must be after activerecord
gem 'json'
gem 'thin'
gem 'mongo'
gem 'bson'
gem 'bson_ext'
gem 'dalli'
gem 'moped'


group :production do
end

group :development do
  gem 'pry'
  gem 'sinatra-contrib'
end

group :test do
  gem 'minitest', "~>2.6", :require => "minitest/autorun"
  gem 'rack-test', :require => "rack/test"
  gem 'factory_girl'
  gem 'database_cleaner'
end