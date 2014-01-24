require 'CSV'
require 'ruby-progressbar'
require 'nokogiri'
require 'active_record'
require 'activerecord-import'
require_relative '../models/init'

def import_file(file)
  trajectory = Trajectory.create(user: @user, upload_date: Time.now)

  points = []

  if File.extname(file) == '.plt'
    points = parse_plt(file, trajectory)
  elsif File.extname(file) == '.gpx'
    points = parse_gpx(file, trajectory)
  end

  Point.import points

  trajectory.update(start_date: trajectory.points.first.date, end_date: trajectory.points.last.date, points_count: points.count)
end

def import_directory(directory)
  files = Dir.entries(ARGV[0])

  progressbar = ProgressBar.create(:total => files.count - 2)

  files.each do |file|
    if file != '.' and file != '..'
      import_file "#{directory}/#{file}"
      progressbar.increment
    end
  end
end

def parse_plt(file, trajectory)
  points = []

  CSV.open(file).drop(6).each do |row|
    points << Point.new(trajectory: trajectory, longitude: row[1].to_f, latitude: row[0].to_f, date: DateTime.parse("#{row[5]} #{row[6]}").to_time)
  end

  points
end

def parse_gpx(file, trajectory)
  doc = Nokogiri::XML(File.open(file))

  points = []

  doc.search('trkpt').each do |trkpt|
    points << Point.new(trajectory: trajectory, longitude: trkpt['lon'], latitude: trkpt['lat'], date: DateTime.parse(trkpt.at('time').text).to_time)
  end

  points
end

abort 'Missing arguments' if ARGV[0] == nil or ARGV[1] == nil

abort 'Path not found' unless File.exists?(ARGV[0])

@user = User.where(:name => ARGV[1]).first_or_create

if File.directory?(ARGV[0])
  import_directory ARGV[0]
elsif File.file?(ARGV[0])
  import_file ARGV[0]
end