# frozen_string_literal: true

require 'base64'
require 'rbnacl/libsodium'
require 'redis'
require_relative 'secure_message'

# Encrypt and Decrypt JSON encoded sessions
class SecureSession
  ## Any use of this library must setup configuration information
  def self.setup(config)
    @config = config
  end

  ## Class methods to create and retrieve cookie salt
  SESSION_SECRET_BYTES = 64

  # Generate secret for sessions
  def self.generate_secret
    secret = RbNaCl::Random.random_bytes(SESSION_SECRET_BYTES)
    Base64.strict_encode64 secret
  end

  def self.secret
    Base64.strict_decode64 @config.SESSION_SECRET
  rescue
    nil
  end

  def self.wipe_redis_sessions
    # redis = Redis.new(url: @config.REDIS_URL)
    redis = Redis.new
    redis.keys.each { |session_id| redis.del session_id }
  end

  ## Instance methods to store and retrieve encrypted session data
  def initialize(session)
    @session = session
  end

  def set(key, value)
    encrypted_value = SecureMessage.encrypt(value)
    @session[key] = Base64.strict_encode64(encrypted_value)
  end

  def get(key)
    return nil unless @session[key]
    encrypted_value = Base64.strict_decode64(@session[key])
    SecureMessage.decrypt(encrypted_value)
  end

  def delete(key)
    @session.delete(key)
  end
end
