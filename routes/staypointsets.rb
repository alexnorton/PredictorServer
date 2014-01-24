class PredictorServer < Sinatra::Base
  get '/staypointset.json' do
    content_type :json

    if params[:trajectory] and params[:distance_threshold] and params[:time_threshold]
      stay_point_set = StayPointSet.find_by(trajectory_id: params[:trajectory], distance_threshold: params[:distance_threshold], time_threshold: params[:time_threshold])
      if stay_point_set
        stay_point_set.stay_points.to_json
      else
        {error: 'Stay point set not found'}.to_json
      end
    end
  end

  get '/staypointset/new.json' do
    content_type :json

    if params[:trajectory] and params[:distance_threshold] and params[:time_threshold]
      stay_point_set = StayPointSet.find_by(trajectory_id: params[:trajectory], distance_threshold: params[:distance_threshold], time_threshold: params[:time_threshold])
      if stay_point_set
        {error: 'Stay point set already exists'}.to_json
      else
        Resque.enqueue(StayPointDetector, params[:trajectory], params[:distance_threshold], params[:time_threshold])
      end
    end
  end
end