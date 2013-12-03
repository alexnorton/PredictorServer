require 'CSV'
require 'active_record'
require './model.rb'

ActiveRecord::Base.establish_connection(
	:adapter => "mysql2",
	:host => "127.0.0.1",
	:username => "root",
	:password => "",
	:database => "predictor"
)

user = User.create(name: "Test")

trajectory = Trajectory.create(user: user, upload_date: Time.now)

CSV.open("trajectory.plt").drop(6).each do |row|
	Point.create(trajectory: trajectory, longitude: row[1].to_f, latitude: row[0].to_f, date: DateTime.parse("#{row[5]} #{row[6]}").to_time)
end

trajectory.update(start_date: trajectory.points.first.date, end_date: trajectory.points.last.date)