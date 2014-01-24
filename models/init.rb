require 'active_record'

ActiveRecord::Base.establish_connection(
    :adapter => 'mysql2',
    :host => '127.0.0.1',
    :username => 'root',
    :password => '',
    :database => 'predictor'
)

require_relative 'model'