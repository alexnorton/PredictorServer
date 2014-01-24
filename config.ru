require 'resque/server'
require_relative 'app'

run Rack::URLMap.new \
  '/' => PredictorServer,
  '/resque' => Resque::Server.new