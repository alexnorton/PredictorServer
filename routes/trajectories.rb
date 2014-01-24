class PredictorServer < Sinatra::Base
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

    #StayPointDetector.perform(params[:id], 200, 5*60)

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
end