require 'RGeo'
require_relative '../models/init'

class Point
  @core_distance
  @reachability_distance
  @point
  @processed

  attr_accessor :core_distance, :reachability_distance, :processed, :point

  def distance(point)
    ::RGeo::Geographic.spherical_factory.point(self.longitude, self.latitude).distance(::RGeo::Geographic.spherical_factory.point(point.longitude, point.latitude))
  end
end

class Cluster
  @points

  def initialize(points)
    @points = points
  end

  def centroid
    Point.new(latitude: @points.map(&:latitude).inject(0, &:+)/@points.length, longitude: @points.map(&:longitude).inject(0, &:+)/@points.length, )
  end

  def region
    centroid = self.centroid
    radius = @points.map{|point| point.distance(centroid)}.max
    return centroid, radius
  end
end

class Clusterer
  @points
  @max_radius
  @min_cluster_size
  @unprocessed
  @ordered

  def initialize(points, max_radius, min_cluster_size)
    @points = points
    @max_radius = max_radius
    @min_cluster_size = min_cluster_size
  end

  def setup
    @points.each do |point|
      point.reachability_distance = nil
      point.processed = false
    end

    @unprocessed = @points.dup
    @ordered = []
  end

  def core_distance(point, neighbours)
    return point.core_distance if point.core_distance
    if neighbours.length >= @min_cluster_size - 1
      sorted_neighbours = neighbours.map{|neighbour| neighbour.distance(point)}.sort
      point.core_distance = sorted_neighbours[@min_cluster_size - 2]
      return point.core_distance
    end
  end

  def neighbours(point)
    @points.select do |p|
        p != point and p.distance(point) <= @max_radius
    end
  end

  def processed(point)
    point.processed = true
    @unprocessed - [point]
    @ordered.push(point)
  end

  def update(neighbours, point, seeds)
    neighbours.select{|n| !n.processed}.each do |neighbour|
      new_reachability_distance = [point.core_distance, point.distance(neighbour)].max
      if !neighbour.reachability_distance
        neighbour.reachability_distance = new_reachability_distance
        seeds.push(neighbour)
      elsif new_reachability_distance < neighbour.reachability_distance
        neighbour.reachability_distance = new_reachability_distance
      end
    end
  end

  def run
    self.setup

    while @unprocessed
      point = @unprocessed[0]

      self.processed(point)
      point_neighbours = self.neighbours(point)

      if self.core_distance(point, point_neighbours)
        seeds = []
        self.update(point_neighbours, point, seeds)

        while seeds
          seeds.sort! {|a,b| a.reachability_distance <=> b.reachability_distance}
          n = seeds.delete_at(0)

          if n
            self.processed(n)

            n_neighbours = self.neighbours(n)

            if self.core_distance(n, n_neighbours)
              self.update(n_neighbours, n, seeds)
            end
          end
        end
      end
    end

    @ordered
  end

  def cluster(cluster_threshold)
    clusters = []
    separators = []

    i = 0

    while i < @ordered.length - 1
      this_i = i
      next_i = i + 1
      this_p = @ordered[i]
      next_p = @ordered[next_i]
      this_rd = this_p.reachability_distance ? this_p.reachability_distance : Float::INFINITY
      next_rd = next_p.reachability_distance ? next_p.reachability_distance : Float::INFINITY

      if this_rd > cluster_threshold
        separators.push(this_i)
      elsif next_rd > cluster_threshold
        separators.push(next_i)
        i += 1
      end

      i += 1
    end

    (separators.length - 1).times do |i|
      start = separators[i] + 1
      finish = separators[i+1]

      if finish - start > @min_cluster_size
          clusters.push(Cluster.new(@ordered[start..finish]))
      end
    end

    clusters
  end
end

ActiveRecord::Base.logger = Logger.new(STDOUT)

points = StayPoint.where(trajectory: Trajectory.last)

clusterer = Clusterer.new(points, 200, 5)
ordered = clusterer.run()
clusters = clusterer.cluster(100)

p clusters