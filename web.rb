require 'sinatra'

get '/' do
	"{}"
end

post '/' do
	print params["data"]
	File.open("#{Time.now.to_i}.csv", 'w') {|f| f.write(params["data"])}
	"{}"
end