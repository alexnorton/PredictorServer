require 'rubypython'

#ActiveRecord::Base.logger = Logger.new(STDOUT)

class Clusterer

  @queue = :queue

  def self.perform(user_id)

    # Clustering parameters
    max_radius = 1000
    min_cluster_size = 2
    cluster_threshold = 999999999

    user = User.find(user_id)
    user.stay_points.update_all(cluster_id: nil)
    user.clusters.destroy_all
    user.edges.destroy_all

    points = user.stay_points.where(stay_point_sets: {distance_threshold: 200, time_threshold: 300})

    results = RubyPython.run do
      # Import clustering module
      sys = RubyPython.import('sys')
      sys.path.append("#{File.expand_path File.dirname(__FILE__)}")
      optics = RubyPython.import('optics')

      # Create Python Point objects
      optics_points = points.map{|point| optics.Point(point.id, point.latitude.to_f, point.longitude.to_f) }

      # Run clustering
      clusterer = optics.Optics(optics_points, max_radius, min_cluster_size)
      clusterer.run
      clusters = clusterer.cluster(cluster_threshold)

      p clusters.to_enum.count

      clusters.to_enum.map do |cluster|
        {   latitude: cluster.points.to_enum.inject(0){|sum, point| sum + point.latitude.rubify } / cluster.points.rubify.size,
            longitude: cluster.points.to_enum.inject(0){|sum, point| sum + point.longitude.rubify } / cluster.points.rubify.size,
            points: cluster.points.to_enum.map{|point| point.id.rubify } }
      end
    end

    visits = []

    results.each do |result|
      cluster = Cluster.create(latitude: result[:latitude], longitude: result[:longitude], user: user)

      result[:points].each do |point|
        stay_point = StayPoint.find(point)
        stay_point.update(cluster: cluster)
        visits << Visit.create(cluster: cluster, arrival_time: stay_point.arrival_time, departure_time: stay_point.departure_time)
      end
    end

    points.each do |point|
      point.reload
      if point.cluster.nil?
        cluster = Cluster.create(latitude: point.latitude, longitude: point.longitude, user: user, stay_points: [point])
        visits << Visit.create(cluster: cluster, arrival_time: point.arrival_time, departure_time: point.departure_time)
      end
    end

    # Build graph edges
    visits.each_with_index do |visit, index|
      next_visit = visits[index + 1]
      if next_visit
        Edge.create(from: visit.cluster, departure_time: visit.departure_time, to: next_visit.cluster, arrival_time: next_visit.arrival_time, user: user)
      end
    end

  end

end