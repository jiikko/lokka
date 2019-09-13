# frozen_string_literal: true

class User
  include DataMapper::Resource

  property :id, Serial
  property :name, String, length: (3..40), unique: true
  property :email, String, length: (5..40), unique: true, format: :email_address
  property :hashed_password, String
  property :salt, String
  property :created_at, DateTime
  property :updated_at, DateTime
  property :permission_level, Integer, default: 1

  has n, :entries

  attr_accessor :password_confirmation
  attr_reader :password

  validates_uniqueness_of :name
  validates_uniqueness_of :email
  validates_length_of :password, minimum: 4, if: :password_require?
  validates_presence_of :password_confirmation, if: :password_require?
  validates_confirmation_of :password

  before :valid? do
    self.name = name.strip
  end

  def password=(pass)
    @password = pass
    self.salt = User.random_string(10) unless salt
    self.hashed_password = User.encrypt(@password, salt) unless @password.blank?
  end

  def self.authenticate(name, pass)
    current_user = first(name: name)
    return nil if current_user.nil?
    return current_user if User.encrypt(pass, current_user.salt) == current_user.hashed_password
    nil
  end

  def admin?
    permission_level == 1
  end

  def password_require?
    new? || (!new? && !password.blank?)
  end

  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest(pass + salt)
  end

  def self.random_string(len)
    Array.new(len) { ['a'..'z', 'A'..'Z', '0'..'9'].map(&:to_a).flatten[rand(62)] }.join
  end
end

class Hash
  def stringify
    each_with_object({}) do |(key, value), options|
      options[key.to_s] = value.to_s
    end
  end

  def stringify!
    each do |key, value|
      delete(key)
      store(key.to_s, value.to_s)
    end
  end
end

class GuestUser
  def admin?
    false
  end

  def permission_level
    0
  end
end
