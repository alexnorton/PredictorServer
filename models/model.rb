require 'active_record'

class User < ActiveRecord::Base
	has_many :trajectories

  def stay_points(distance_threshold, time_threshold)
    self.trajectories.inject([]) do |result, trajectory|
      stay_point_sets = trajectory.try(:stay_point_sets).find_by(distance_threshold: distance_threshold, time_threshold: time_threshold)
      if stay_point_sets
        stay_points = stay_point_sets.try(:stay_points)
        if stay_points
          result.concat stay_points
        else
          []
        end
      else
        []
      end
    end
  end
end

class Trajectory < ActiveRecord::Base
	belongs_to :user
	has_many :points
  has_many :stay_point_sets

  def enqueue_stay_point_detection(distance_threshold, time_threshold)
    Resque.enqueue(StayPointDetector, self.id, distance_threshold, time_threshold)
  end
end

class Point < ActiveRecord::Base
	belongs_to :trajectory, counter_cache: true
end

class StayPoint < ActiveRecord::Base
  belongs_to :trajectory
  belongs_to :stay_point_set
end

class StayPointSet < ActiveRecord::Base
  belongs_to :trajectory
  has_many :stay_points
end

class StayPointCluster

end

class Traversal

end