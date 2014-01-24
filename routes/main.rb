class PredictorServer < Sinatra::Base
  get '/' do
    erb 'Hello!'
  end
end