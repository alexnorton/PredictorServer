require 'rserve'
require_relative '../models/init'

connection = Rserve::Connection.new

x=con.eval('x<-rnorm(1)')