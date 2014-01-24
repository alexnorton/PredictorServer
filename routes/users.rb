class PredictorServer < Sinatra::Base
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

    User.find(params[:id]).stay_points(200, 300).map {|stay_point| {
    				:type => 'Point',
                :coordinates => [stay_point.longitude, stay_point.latitude],
                :properties => {
                    :arrival_time => stay_point.arrival_time,
                    :departure_time => stay_point.departure_time
                }
    			}
    		}.to_json
  end

  get '/users/:id/staypoints/detect' do
    User.find(params[:id]).trajectories.each do |trajectory|
      trajectory.enqueue_stay_point_detection(200, 300)
    end

    ''
  end

  get '/users/:id' do
    @user = User.find(params[:id])
    erb :user
  end
end