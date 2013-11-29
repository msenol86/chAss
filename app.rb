require 'sinatra'
require 'mongo'

# I did not test my code because I do not know anything about Ruby test tools

get '/' do
  "Front Page"
end

get '/companies/:id' do
  "Get details about a company with id: #{params[:id]}"
end

get '/companies' do
  "Get List of All Companies"
end

post '/companies' do
  "Create a new Company"
end

# can be patch
put '/companies/:id' do
  "Update company with id: #{params[:id]}"
end
