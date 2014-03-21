require 'active_record'

class User < ActiveRecord::Base
	has_many :trajectories
  has_many :stay_points, :through => :trajectories
  has_many :stay_point_sets, :through => :trajectories
  has_many :clusters
  has_many :visits, :through => :clusters
  has_many :edges

  def stay_point_set_groups
    self.stay_point_sets.group(:distance_threshold, :time_threshold).map do |stay_point_set|
      count = self.stay_points.where(stay_point_sets: {distance_threshold: stay_point_set.distance_threshold, time_threshold: stay_point_set.time_threshold}).count

      {
        :distance_threshold => stay_point_set.distance_threshold,
        :time_threshold => stay_point_set.time_threshold,
        :count => count
      }
    end
  end

  def enqueue_stay_point_detection(distance_threshold, time_threshold)
    self.trajectories.each do |trajectory|
      Resque.enqueue(StayPointDetector, trajectory.id, distance_threshold, time_threshold)
    end
  end

  def enqueue_clustering()
    Resque.enqueue(Clusterer, self.id)
  end
end

class Trajectory < ActiveRecord::Base
	belongs_to :user
	has_many :points
  has_many :stay_points, :through => :stay_point_sets
  has_many :stay_point_sets
end

class Point < ActiveRecord::Base
	belongs_to :trajectory, counter_cache: true
end

class StayPoint < ActiveRecord::Base
  belongs_to :trajectory
  belongs_to :stay_point_set
  belongs_to :cluster
end

class StayPointSet < ActiveRecord::Base
  belongs_to :trajectory
  has_many :stay_points
end

class Cluster < ActiveRecord::Base
  belongs_to :user
  has_many :stay_points
  has_many :visits, :dependent => :destroy
end

class Visit < ActiveRecord::Base
  belongs_to :cluster
end

class Edge < ActiveRecord::Base
  belongs_to :from, class_name: "Cluster"
  belongs_to :to, class_name: "Cluster"
  belongs_to :user
end