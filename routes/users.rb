require 'rubypython'

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

    User.find(params[:id]).stay_points.where(stay_point_sets: {distance_threshold: 200, time_threshold: 300}).map {|stay_point| {
    				:type => 'Point',
                :coordinates => [stay_point.longitude, stay_point.latitude],
                :properties => {
                    :arrival_time => stay_point.arrival_time,
                    :departure_time => stay_point.departure_time
                }
    			}
    		}.to_json
  end

  get '/users/:id/staypoints' do

    @groups = User.find(params[:id]).stay_point_set_groups

    erb :user_staypoints
  end

  get '/users/:id/staypoints/detect' do
    User.find(params[:id]).trajectories.each do |trajectory|
      trajectory.enqueue_stay_point_detection(200, 300)
    end

    ''
  end

  get '/users/:id/clusters.json' do
    content_type :json

    User.find(params[:id]).clusters.map {|cluster| {
        :type => 'Point',
        :coordinates => [cluster.longitude, cluster.latitude]
    }}.to_json
  end

  get '/users/:id' do
    @user = User.find(params[:id])
    erb :user
  end


end