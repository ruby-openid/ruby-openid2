require 'uri'

module OpenID
  module URINorm
    VALID_URI_SCHEMES = %w[http https].freeze

    def self.urinorm(uri)
      uri = URI.parse(uri)

      raise URI::InvalidURIError.new('no scheme') unless uri.scheme

      uri.scheme = uri.scheme.downcase
      raise URI::InvalidURIError.new('Not an HTTP or HTTPS URI') unless VALID_URI_SCHEMES.member?(uri.scheme)

      raise URI::InvalidURIError.new('no host') if uri.host.nil? # For Ruby 2.7

      raise URI::InvalidURIError.new('no host') if uri.host.empty? # For Ruby 3+

      uri.host = uri.host.downcase

      uri.path = remove_dot_segments(uri.path)
      uri.path = '/' if uri.path.empty?

      uri = uri.normalize.to_s
      uri.gsub(PERCENT_ESCAPE_RE) do
        sub = ::Regexp.last_match(0)[1..2].to_i(16).chr
        reserved(sub) ? ::Regexp.last_match(0).upcase : sub
      end
    end

    RESERVED_RE = /[A-Za-z0-9._~-]/
    PERCENT_ESCAPE_RE = /%[0-9a-zA-Z]{2}/

    def self.reserved(chr)
      !(RESERVED_RE =~ chr)
    end

    def self.remove_dot_segments(path)
      result_segments = []

      while path.length > 0
        if path.start_with?('../')
          path = path[3..-1]
        elsif path.start_with?('./')
          path = path[2..-1]
        elsif path.start_with?('/./')
          path = path[2..-1]
        elsif path == '/.'
          path = '/'
        elsif path.start_with?('/../')
          path = path[3..-1]
          result_segments.pop if result_segments.length > 0
        elsif path == '/..'
          path = '/'
          result_segments.pop if result_segments.length > 0
        elsif ['..', '.'].include?(path)
          path = ''
        else
          i = 0
          i = 1 if path[0].chr == '/'
          i = path.index('/', i)
          i = path.length if i.nil?
          result_segments << path[0...i]
          path = path[i..-1]
        end
      end

      result_segments.join('')
    end
  end
end
