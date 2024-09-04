require "openid/cryptutil"
require "date"
require "time"

module OpenID
  module Nonce
    DEFAULT_SKEW = 60 * 60 * 5
    TIME_FMT = "%Y-%m-%dT%H:%M:%SZ"
    TIME_STR_LEN = "0000-00-00T00:00:00Z".size
    @@NONCE_CHRS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    TIME_VALIDATOR = /\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ/

    @skew = DEFAULT_SKEW

    # The allowed nonce time skew in seconds.  Defaults to 5 hours.
    # Used for checking nonce validity, and by stores' cleanup methods.
    def self.skew
      @skew
    end

    def self.skew=(new_skew)
      @skew = new_skew
    end

    # Extract timestamp from a nonce string
    def self.split_nonce(nonce_str)
      timestamp_str = nonce_str[0...TIME_STR_LEN]
      raise ArgumentError if timestamp_str.size < TIME_STR_LEN
      raise ArgumentError unless timestamp_str.match(TIME_VALIDATOR)

      ts = Time.parse(timestamp_str).to_i
      raise ArgumentError if ts < 0

      [ts, nonce_str[TIME_STR_LEN..-1]]
    end

    # Is the timestamp that is part of the specified nonce string
    # within the allowed clock-skew of the current time?
    def self.check_timestamp(nonce_str, allowed_skew = nil, now = nil)
      allowed_skew = skew if allowed_skew.nil?
      begin
        stamp, = split_nonce(nonce_str)
      rescue ArgumentError # bad timestamp
        return false
      end
      now ||= Time.now.to_i

      # times before this are too old
      past = now - allowed_skew

      # times newer than this are too far in the future
      future = now + allowed_skew

      (past <= stamp and stamp <= future)
    end

    # generate a nonce with the specified timestamp (defaults to now)
    def self.mk_nonce(time = nil)
      salt = CryptUtil.random_string(6, @@NONCE_CHRS)
      t = if time.nil?
        Time.now.getutc
      else
        Time.at(time).getutc
      end
      time_str = t.strftime(TIME_FMT)
      time_str + salt
    end
  end
end
