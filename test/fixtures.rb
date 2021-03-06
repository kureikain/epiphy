require 'rethinkdb'
include RethinkDB::Shortcuts

RETHINKDB_DB_TEST = 'epiphy_test_v001'
# Cleanup and Reset the database before testing
puts "Cleaning the test database"

puts Time.new.asctime
host = ENV['WERCKER_RETHINKDB_HOST'] || 'localhost'
if host=='localhost'
  puts "Local test. Will connect to local rethink"
else
  puts "CI detected. Will connect to #{host}"
end

puts 'Connect to Rethink ' + Time.new.asctime
connection = r.connect(:host => host)
puts 'Succesfully connect at ' + Time.new.asctime

begin
  r.db_drop(RETHINKDB_DB_TEST).run connection
rescue
end

begin 
  r.db_create(RETHINKDB_DB_TEST).run connection
rescue 
  puts "Fail to creating database. Fix this and return"
  exit
ensure

end

# Create testing table
# @TODO consider use table create for testing 
[:users, :article, :customuser, :user, :movie, :film].each do |t|
  r.db(RETHINKDB_DB_TEST).table_create(t).run connection
end

Epiphy::Repository.configure do |config|
  config.adapter = Epiphy::Adapter::Rethinkdb.new connection, database: RETHINKDB_DB_TEST
end

class User
  include Epiphy::Entity
  self.attributes = :name, :age
end

class Article
  include Epiphy::Entity
  self.attributes = :user_id, :unmapped_attribute, :title, :comments_count, :rank
end

class Movie
  include Epiphy::Entity
  self.attributes = :title, :url, :type
end

class CustomUserRepository
  include Epiphy::Repository
end

class UserRepository
  include Epiphy::Repository
end

class ArticleRepository
  include Epiphy::Repository

  def self.rank
    query do |r|
      #r.oreder
    end
  end

  def self.highest_rank
    query do |r, rt|
      r.order_by(rt.desc('rank')).limit(1)
    end
  end

  def self.by_user(user)
    query do |r|
      r.filter({user_id: user.id})
    end
  end

  def self.not_by_user(user)
    exclude by_user(user)
  end

  def self.rank_by_user(user)
    rank.by_user(user)
  end
end

class MovieRepository
  include Epiphy::Repository
  self.collection= :film
end
puts "Finish preparing. #{Time.new.asctime}"
