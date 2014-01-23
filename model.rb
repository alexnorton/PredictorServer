class User < ActiveRecord::Base

	has_many :trajectories
end

class Trajectory < ActiveRecord::Base
	belongs_to :user
	has_many :points
end

class Point < ActiveRecord::Base
	belongs_to :trajectory, counter_cache: true
end

class StayPoint < ActiveRecord::Base
  belongs_to :trajectory
end

class StayPointCluster

end

class Traversal

end