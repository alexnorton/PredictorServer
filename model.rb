class User < ActiveRecord::Base
	has_many :trajectories
end

class Trajectory < ActiveRecord::Base
	belongs_to :user
	has_many :points
end

class Point < ActiveRecord::Base
	belongs_to :trajectory
end