require 'sinatra'
require 'active_record'
require 'json'
require 'CSV'
require './model.rb'

configure do
	ActiveRecord::Base.establish_connection(
		:adapter => 'mysql2',
		:host => '127.0.0.1',
		:username => 'root',
		:password => '',
		:database => 'predictor'
	)
end

get '/users.json' do
	User.all.to_json
end

get '/users/new' do
	User.create(name: params[:name]).to_json
end

get '/trajectories.json' do
	content_type :json

	Trajectory.all.to_json
end

get '/trajectories/:id.json' do
	content_type :json

	trajectory = Trajectory.find(params[:id])

    {:type => 'LineString', :coordinates => trajectory.points.map{ |point| [point.latitude, point.longitude] }}.to_json
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