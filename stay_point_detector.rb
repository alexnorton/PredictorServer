require 'RGeo'

class StayPointDetector
  @spherical_factory

  def initialize
    @spherical_factory = ::RGeo::Geographic.spherical_factory
  end

  def detect(trajectory, distance_threshold, time_threshold)
    trajectory_points = trajectory.points.map {|point| { \
        :point => @spherical_factory.point(point.longitude, point.latitude), \
			  :datetime => point.date.to_datetime \
			} \
    }

    stay_points = Array.new

    points = Array.new

    trajectory_points.each_with_index do |point1, i|

      if(!points.include?(point1))
        points = Array.new
        stay_point = false

        trajectory_points.drop(i).each do |point2|
          break if point1[:point].distance(point2[:point]) > distance_threshold

          stay_point = true if ((point2[:datetime] - point1[:datetime]) * 24 * 60 * 60) > time_threshold

          points.push(point2)
        end

        if stay_point == true
          longitude = points.inject(0){|sum, point| sum + point[:point].x } / points.size
          latitude = points.inject(0){|sum, point| sum + point[:point].y } / points.size

          stay_points.push(StayPoint.new(latitude: latitude, longitude: longitude, trajectory: trajectory, arrival_time: points.first[:datetime], departure_time: points.last[:datetime]))
        end
      end
    end

    stay_points
  end
end