require 'rubypython'
require_relative '../models/init'

# Clustering parameters
max_radius = 500
min_cluster_size = 2
cluster_threshold = 9999999

user = User.find(12)

Cluster.delete_all(user: user)

points = user.stay_points.where(stay_point_sets: {distance_threshold: 200, time_threshold: 300})

RubyPython.start

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

clusters.to_enum.each do |cluster|

  # Calculate average latlong for clusters
  latitude = cluster.points.to_enum.inject(0){|sum, point| sum + point.latitude.rubify } / cluster.points.rubify.size
  longitude = cluster.points.to_enum.inject(0){|sum, point| sum + point.longitude.rubify } / cluster.points.rubify.size

  # Create ActiveRecord Cluster objects
  Cluster.create(latitude: latitude, longitude: longitude, user: user)

end

RubyPython.stop

