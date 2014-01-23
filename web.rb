require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/simple-navigation'
require 'active_record'
require 'json'
require 'CSV'
require 'polylines'
require_relative 'model'
require_relative 'numeric'
require_relative 'stay_point_detector'

configure do
	ActiveRecord::Base.establish_connection(
		:adapter => 'mysql2',
		:host => '127.0.0.1',
		:username => 'root',
		:password => '',
		:database => 'predictor'
	)

  ActiveRecord::Base.logger = Logger.new(STDOUT)

  after do
    ActiveRecord::Base.connection.close
  end
end

get '/' do
  erb 'Hello!'
end

get '/users' do
  erb :users
end

get '/users.json' do
	User.all.to_json
end

get '/users/new.json' do
	User.create(name: params[:name]).to_json
end

get '/users/:id/staypoints.json' do
  content_type :json

  stay_point_detector = StayPointDetector.new
  user = User.find(params[:id])

  response = Array.new

  user.trajectories.each do |trajectory|
    stay_point_detector.detect(trajectory, 200, 20*60).each {|stay_point| response.push({
						:type => 'Point',
              :coordinates => [stay_point.longitude, stay_point.latitude],
              :properties => {
                  :arrival_time => stay_point.arrival_time,
                  :departure_time => stay_point.departure_time
              }
					})
				}
  end

  response.to_json
end

get '/users/:id' do
  @user = User.find(params[:id])
  erb :user
end

get '/trajectories' do
  @trajectories = Trajectory.includes(:user)

  erb :trajectories
end

get '/trajectories.json' do
	content_type :json

	Trajectory.all.to_json
end

get '/trajectories/:id.json' do
  content_type :json

  trajectory = Trajectory.find(params[:id])

  {:type => 'LineString', :coordinates => trajectory.points.map{ |point| [point.longitude, point.latitude] }}.to_json
end

get '/trajectories/:id/staypoints.json' do
  content_type :json

  trajectory = Trajectory.find(params[:id])
  stay_point_detector = StayPointDetector.new
  stay_points = stay_point_detector.detect(trajectory, 200, 5*60)

  (stay_points.map {|stay_point| {
						:type => 'Point',
						:coordinates => [stay_point.longitude, stay_point.latitude],
						:properties => {
							:arrival_time => stay_point.arrival_time,
							:departure_time => stay_point.departure_time
						}
					}
				}).to_json
end

get '/trajectories/:id' do
  @trajectory = Trajectory.find(params[:id])

  erb :trajectory
end

post '/trajectories/new.json' do
	content_type :json

	user = User.find_by name: 'Upload'

	trajectory = Trajectory.create(user: user, upload_date: Time.now)

	CSV.parse(params['data']).each do |row|
		Point.create(trajectory: trajectory, longitude: row[2].to_f, latitude: row[1].to_f, date: Time.at(row[0].to_i))
	end

	trajectory.update(start_date: trajectory.points.first.date, end_date: trajectory.points.last.date)

	trajectory.to_json
end