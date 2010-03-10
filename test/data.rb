require 'dm-constraints'

class User
  include DataMapper::Resource

  property :id, Serial
  property :name, String

  has n, :articles

  def self.current
    first
  end
end

class Article
  include DataMapper::Resource

  property :id,    Serial
  property :title, String
  property :number,Integer
  timestamps :at

  belongs_to :user

  is :watched
end

class Unwatched
  include DataMapper::Resource
  property :id,    Serial
end

class Student
  include DataMapper::Resource

  property :id,     Serial
  property :name,   String, :default => "student"
  property :age,    Integer, :default => 5
  property :is_werewolf, Boolean, :default => false
  timestamps :at

  is :watched, :except => [:name, :age]
end

class Camper
  include DataMapper::Resource
  property :id,     Serial
  property :name,   String, :default => "camper"
  property :age,    Integer, :default => 5
  property :is_werewolf, Boolean, :default => false
  timestamps :at

  is :watched, :only => [:name, :age]
end

class Pig
  include DataMapper::Resource
  property :id,     Serial
  property :name,   String
  is :watched

  has n, :babies, :constraint => :destroy
end

class Baby
  include DataMapper::Resource
  property :id,     Serial
  property :name,   String
  is :watched

  belongs_to :pig
end

class Rifle
  include DataMapper::Resource
  property :id,     Serial
  property :name,   String
  has n, :ammos
  is :watched, :version_model => "ScopedVersion"
end

class Ammo
  include DataMapper::Resource
  property :id,     Serial
  property :name,   String
  belongs_to :rifle
  is :watched, :scope => :rifle, :version_model => "ScopedVersion"
end

DataMapper.setup(:default, 'sqlite3::memory:')
DataMapper.auto_migrate! if defined?(DataMapper)

