require 'sinatra'
require 'mongo'
require 'json/ext'

# I did not test my code because I do not know anything about Ruby test tools

include Mongo

def get_connection
  return @db_connection if @db_connection
  db = URI.parse(ENV['MONGOHQ_URL'])
  db_name = db.path.gsub(/^\//, '')
  @db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
  @db_connection
end


configure do
  conn = get_connection
  set :mongo_connection, conn
  set :mongo_db, conn.db('chass')
end

set :protection, :except => [:http_origin]

coll = settings.mongo_db['chass']
company_required_fields = ["company_id", "name", "address", "city", "country", "owners_directors"]
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
      owners_directors = params[:owners_directors]
      c = 0
      owners_directors = owners_directors.map do |elem|
        c = c + 1
        [c.to_s, {:name => elem}]
      end
      owners_directors.flatten!
      owners_directors = Hash[*owners_directors]
      owners_directors = {:owners_directors => owners_directors}
      params.delete_if { |key, value| key == "owners_directors"}
      params.merge!(owners_directors)
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
    coll.insert({:company_id => 1, :name => "Google", :address => "Pal Alto", :city => "California", :country => "USA", :email => "info@google.com", :phone_number => "1800030303", :owners_directors => {'1' => {:name => "Sergey Brin"}, '2' => {:name => "Larry Page"}}})
    coll.insert({:company_id => 2, :name => "Apple", :address => "Infinite Loop", :city => "California", :country => "USA", :email => "info@apple.com", :phone_number => "1804345", :owners_directors => {'1' => {:name => "Steve Jobs"}}})
    coll.find.to_a.to_json
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