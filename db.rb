require 'dm-core'
require 'dm-types'
require 'dm-migrations'
require 'dm-validations'

DataMapper::Logger.new(STDOUT, :debug) if ENV['DEBUG']
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3:///#{Dir.pwd}/devel.db")


class Language
  include DataMapper::Resource
#  property :id      , Serial
  property :name    , String        , :key => true

  has n, :films, :through => Resource

  def to_s
    "#{name}"
  end
end

class Subtitle
  include DataMapper::Resource
  property :name    , String  , :key => true

  has n, :films

  def to_s
    "#{name}"
  end
end

=begin
class Person
  include DataMapper::Resource
  property :name    , String        , :key => true
  property :role    , Discriminator , :key => true

  has n, :films, :through => Resource

  def to_s
    "#{name}"
  end
end
=end
class Director
  include DataMapper::Resource
  property :name    , String        , :key => true

  has n, :films, :through => Resource

  def to_s
    "#{name}"
  end
end
class Producer
  include DataMapper::Resource
  property :name    , String        , :key => true

  has n, :films, :through => Resource

  def to_s
    "#{name}"
  end
end
class Writer
  include DataMapper::Resource
  property :name    , String        , :key => true

  has n, :films, :through => Resource

  def to_s
    "#{name}"
  end
end


class Country
  include DataMapper::Resource
  property :name    , String , :key => true

  has n, :films, :through => Resource

  def to_s
    "#{name}" #+ " (#{films.count} film#{'s' unless films.count == 1})"
  end
end


class Distributor
  include DataMapper::Resource
  property :name , String  , :key => true

  has n, :films

  def to_s
    name
  end
end

class Section
  include DataMapper::Resource
  property :name    , String , :key => true

  has n, :films

  def to_s
    "#{name}" #+ " (#{films.count} film#{'s' unless films.count == 1})"
  end
end

class Category
  include DataMapper::Resource
  property :name    , String , :key => true

  has n, :films

  def to_s
    "#{name}" #+ " (#{films.count} film#{'s' unless films.count == 1})"
  end
end



class Venue
  include DataMapper::Resource
  property :name    , String , :key => true

  has n, :sessions
  has n, :films    , :through => :sessions

  def to_s
    "#{name}"
  end
end


class Session
  include DataMapper::Resource
  property :id      , Serial
  property :date    , Date
  property :time    , Time

  belongs_to :venue
  has n    , :films , :through => Resource

  def to_s
    "#{id}"
  end
end


class Year
  include DataMapper::Resource
  property :name , Integer , :key => true

  has n, :films

  def to_s
    "#{name}"
  end
end


class Media
  include DataMapper::Resource
  property :name , String  , :length => (0..32) , :key => true

  has n, :films

  def to_s
    "#{name}"
  end
end


class Film
  include DataMapper::Resource
  property :id               , Serial
  property :title            , String  , :length => (1..128)  , :required => true
  #property :year             , Integer
  property :three_d          , Boolean
  property :still_url        , String  , :length => (10..128)
  property :trailer_url      , String  , :length => (10..128)
  property :tagline          , Text    , :length => (0..512)
  property :synopsis         , Text    , :length => (0..8192)
  property :duration         , Integer #, :nullable => true
  property :distributor_type , String  , :length => (0..8)
  #property :rating      , String
 
  default_scope(:default).update(:order => [:title])
 
  belongs_to :year               , :required => false
  belongs_to :media              , :required => false
  belongs_to :category           , :required => false
  belongs_to :section            , :required => false
  belongs_to :distributor        , :required => false
  belongs_to :subtitle           , :required => false
  has n    , :countries          , :through => Resource
  has n    , :sessions           , :through => Resource
  has n    , :languages          , :through => Resource
  has n    , :directors          , :through => Resource
  has n    , :producers          , :through => Resource
  has n    , :writers            , :through => Resource

  def to_s
    "#{title}" #+ (countries ? ", #{countries.join('/')}": '') + ", #{year} (#{section})"
  end
end


DataMapper.auto_upgrade!
#DataMapper.auto_migrate!

