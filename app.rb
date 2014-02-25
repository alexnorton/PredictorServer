require 'sinatra/base'
require 'sinatra/content_for'
require 'sinatra/simple-navigation'
require 'active_record'
require 'json'
require 'CSV'
require 'resque'
require_relative 'helpers/init'
require_relative 'models/init'
require_relative 'routes/init'
require_relative 'lib/stay_point_detector'

class PredictorServer < Sinatra::Base
  helpers Sinatra::ContentFor

  set :root, File.dirname(__FILE__)

  after do
    ActiveRecord::Base.connection.close
  end
end