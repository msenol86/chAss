require 'sinatra'
require 'mongo'
require 'json/ext'

# I did not test my code because I do not know anything about Ruby test tools

include Mongo

configure do
  conn = MongoClient.new("localhost", 27017)
  set :mongo_connection, conn
  set :mongo_db, conn.db('chass')
end

set :protection, :except => [:http_origin]

coll = settings.mongo_db['chass']
company_required_fields = ["company_id", "name", "adress", "city", "country", "owners_directors"]
company_non_required_fields = ["email", "phone_number"]
company_all_fields = ["company_id", "name", "address", "city", "country", "email", "phone_number", "owners_directors"]

get '/' do
  "Front Page"
end

# Get company with id
get '/companies/:id' do
  content_type :json
  coll.find_one(:company_id => params[:id].to_i).to_json
end

# Get all companies
get '/companies' do
  content_type :json
  coll.find.to_a.to_json
end

# Create a new company
post '/companies' do
  content_type :json
  unless params[:company_id].nil? && params[:name].nil? && params[:address].nil? && params[:city].nil? && params[:country].nil? && params[:owners_directors].nil?
    if coll.find({:company_id => params[:company_id].to_i}).count == 0
      tmp = {"company_id" => params[:company_id].to_i}
      params.merge!(tmp)
      new_id = coll.insert params
      coll.find_one(:_id => new_id).to_json
    end
  end
end

# can be patch
# Update company with id
put '/companies/:company_id' do
  content_type :json
  params.delete_if { |key, value| value == '' }
  tmp_id = params[:company_id].to_i
  if coll.find({:company_id => tmp_id}).count != 0
    update_set_data = params.delete_if { |key, value| !(company_all_fields.include? key) }
    update_set_data.delete_if { |key, value| key == "company_id"}
    coll.update({:company_id => tmp_id}, {"$set" => update_set_data})
    coll.find_one({:company_id => tmp_id}).to_json
  end
end

# Initialize db and insert some examples
post '/companies/initDB' do
  content_type :json
  coll.remove()
  if coll.find({:company_id => 1}).count == 0
    new_id = coll.insert({:company_id => 1, :name => "Google", :address => "Pal Alto", :city => "California", :country => "USA", :email => "info@google.com", :phone_number => "1800030303", :owners_directors => {'1' => {:name => "Sergey Brin"}, '2' => {:name => "Larry Page"}}})
    coll.find_one(:_id => new_id).to_json
  end
end

# Upload Passport PDF of Owners and Directors
put '/companies/:company_id/person/:person_id' do
  content_type :json
  File.open('uploads/' + params['passport_pdf_file'][:filename], "w") do |f|
    f.write(params['passport_pdf_file'][:tempfile].read)
  end
  coll.update({:company_id => params[:company_id].to_i}, {"$set" => {"owners_directors.#{params[:person_id].to_i}.passport_file" => params['passport_pdf_file'][:filename]}})
  coll.find_one({:company_id => params[:company_id].to_i}).to_json
end

post '/testParams' do
  puts params
end