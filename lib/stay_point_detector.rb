require 'RGeo'

class StayPointDetector
  @queue = :queue
  @spherical_factory

  def initialize
    @spherical_factory = ::RGeo::Geographic.spherical_factory
  end

  def self.perform(trajectory_id, distance_threshold, time_threshold)
    distance_threshold = distance_threshold.to_i
    time_threshold = time_threshold.to_i

    trajectory = Trajectory.find(trajectory_id)
    stay_point_set = StayPointSet.create(trajectory: trajectory, distance_threshold: distance_threshold, time_threshold: time_threshold)
    stay_points = self.new.detect(trajectory, distance_threshold, time_threshold)
    #stay_point_set.stay_points = stay_points
    stay_points.each do |stay_point|
      stay_point.stay_point_set = stay_point_set
      stay_point.save
    end
  end

  def detect(trajectory, distance_threshold, time_threshold)
    trajectory_points = trajectory.points.map {|point| {
        :point => @spherical_factory.point(point.longitude, point.latitude),
			  :datetime => point.date.to_datetime
			}
    }

    stay_points = Array.new

    points = Array.new

    trajectory_points.each_with_index do |point1, i|

      unless points.include?(point1)
        points = Array.new
        stay_point = false

        trajectory_points.drop(i).each do |point2|
          break if point1[:point].distance(point2[:point]) > distance_threshold

          stay_point = true if ((point2[:datetime] - point1[:datetime]) * 24 * 60 * 60) > time_threshold

          points.push(point2)
        end

        if stay_point
          longitude = points.inject(0){|sum, point| sum + point[:point].x } / points.size
          latitude = points.inject(0){|sum, point| sum + point[:point].y } / points.size

          stay_points.push(StayPoint.new(latitude: latitude, longitude: longitude, trajectory: trajectory, arrival_time: points.first[:datetime], departure_time: points.last[:datetime]))
        end
      end
    end

    stay_points
  end
end