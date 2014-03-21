require 'RGeo'
require 'Singleton'

class Spherical_Factory < ::RGeo::Geographic
  include Singleton

  attr_accessor :factory

  @factory

  def initialize
    @factory = self.spherical_factory
  end
end