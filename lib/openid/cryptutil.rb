# stdlib
require "digest/sha1"
require "digest/sha2"
begin
  require "openssl"
rescue LoadError
  begin
    # Try loading the ruby-hmac files if they exist
    require "hmac-sha1"
    require "hmac-sha2"
  rescue LoadError
    # Nothing exists use included hmac files
    require_relative "../hmac/sha1"
    require_relative "../hmac/sha2"
  end
end

# This library
require_relative "util"

module OpenID
  # This module contains everything needed to perform low-level
  # cryptograph and data manipulation tasks.
  module CryptUtil
    # Generate a random number, doing a little extra work to make it
    # more likely that it's suitable for cryptography. If your system
    # doesn't have /dev/urandom then this number is not
    # cryptographically safe. See
    # <http://www.cosine.org/2007/08/07/security-ruby-kernel-rand/>
    # for more information.  max is the largest possible value of such
    # a random number, where the result will be less than max.
    def self.rand(max)
      Kernel.srand
      Kernel.rand(max)
    end

    def self.sha1(text)
      Digest::SHA1.digest(text)
    end

    def self.hmac_sha1(key, text)
      return HMAC::SHA1.digest(key, text) unless defined? OpenSSL

      OpenSSL::HMAC.digest(OpenSSL::Digest.new("SHA1"), key, text)
    end

    def self.sha256(text)
      Digest::SHA256.digest(text)
    end

    def self.hmac_sha256(key, text)
      return HMAC::SHA256.digest(key, text) unless defined? OpenSSL

      OpenSSL::HMAC.digest(OpenSSL::Digest.new("SHA256"), key, text)
    end

    # Generate a random string of the given length, composed of the
    # specified characters.  If chars is nil, generate a string
    # composed of characters in the range 0..255.
    def self.random_string(length, chars = nil)
      s = ""

      if chars.nil?
        length.times { s += rand(256).chr }
      else
        length.times { s += chars[rand(chars.length)] }
      end
      s
    end

    # Convert a number to its binary representation; return a string
    # of bytes.
    def self.num_to_binary(n)
      bits = n.to_s(2)
      prepend = (8 - bits.length % 8)
      bits = ("0" * prepend) + bits
      [bits].pack("B*")
    end

    # Convert a string of bytes into a number.
    def self.binary_to_num(s)
      # taken from openid-ruby 0.0.1
      s = "\000" * (4 - (s.length % 4)) + s
      num = 0
      s.unpack("N*").each do |x|
        num <<= 32
        num |= x
      end
      num
    end

    # Encode a number as a base64-encoded byte string.
    def self.num_to_base64(l)
      OpenID::Util.to_base64(num_to_binary(l))
    end

    # Decode a base64 byte string to a number.
    def self.base64_to_num(s)
      binary_to_num(OpenID::Util.from_base64(s))
    end

    def self.const_eq(s1, s2)
      return false if s1.length != s2.length

      result = true
      s1.length.times do |i|
        result &= (s1[i] == s2[i])
      end
      result
    end
  end
end
