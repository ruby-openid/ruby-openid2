require "net/http"
require "openid/util"
require "openid/version"

begin
  require "net/https"
rescue LoadError
  OpenID::Util.log("WARNING: no SSL support found.  Will not be able " +
                   "to fetch HTTPS URLs!")
  require "net/http"
end

MAX_RESPONSE_KB = 10_485_760 # 10 MB (can be smaller, I guess)

module Net
  class HTTP
    def post_connection_check(hostname)
      check_common_name = true
      cert = @socket.io.peer_cert
      cert.extensions.each do |ext|
        next if ext.oid != "subjectAltName"

        ext.value.split(/,\s+/).each do |general_name|
          if /\ADNS:(.*)/ =~ general_name
            check_common_name = false
            reg = Regexp.escape(::Regexp.last_match(1)).gsub("\\*", "[^.]+")
            return true if /\A#{reg}\z/i.match?(hostname)
          elsif /\AIP Address:(.*)/ =~ general_name
            check_common_name = false
            return true if ::Regexp.last_match(1) == hostname
          end
        end
      end
      if check_common_name
        cert.subject.to_a.each do |oid, value|
          if oid == "CN"
            reg = Regexp.escape(value).gsub("\\*", "[^.]+")
            return true if /\A#{reg}\z/i.match?(hostname)
          end
        end
      end
      raise OpenSSL::SSL::SSLError, "hostname does not match"
    end
  end
end

module OpenID
  # Our HTTPResponse class extends Net::HTTPResponse with an additional
  # method, final_url.
  class HTTPResponse
    attr_accessor :final_url, :_response

    class << self
      def _from_net_response(response, final_url, _headers = nil)
        instance = new
        instance._response = response
        instance.final_url = final_url
        instance
      end
    end

    def method_missing(method, *args)
      @_response.send(method, *args)
    end

    def respond_to_missing?(method_name, include_private = false)
      super
    end

    def body=(s)
      @_response.instance_variable_set(:@body, s)
      # XXX Hack to work around ruby's HTTP library behavior.  @body
      # is only returned if it has been read from the response
      # object's socket, but since we're not using a socket in this
      # case, we need to set the @read flag to true to avoid a bug in
      # Net::HTTPResponse.stream_check when @socket is nil.
      @_response.instance_variable_set(:@read, true)
    end
  end

  class FetchingError < OpenIDError
  end

  class HTTPRedirectLimitReached < FetchingError
  end

  class SSLFetchingError < FetchingError
  end

  @fetcher = nil

  def self.fetch(url, body = nil, headers = nil,
    redirect_limit = StandardFetcher::REDIRECT_LIMIT)
    fetcher.fetch(url, body, headers, redirect_limit)
  end

  def self.fetcher
    @fetcher = StandardFetcher.new if @fetcher.nil?

    @fetcher
  end

  def self.fetcher=(fetcher)
    @fetcher = fetcher
  end

  # Set the default fetcher to use the HTTP proxy defined in the environment
  # variable 'http_proxy'.
  def self.fetcher_use_env_http_proxy
    proxy_string = ENV["http_proxy"]
    return unless proxy_string

    proxy_uri = URI.parse(proxy_string)
    @fetcher = StandardFetcher.new(
      proxy_uri.host,
      proxy_uri.port,
      proxy_uri.user,
      proxy_uri.password,
    )
  end

  class StandardFetcher
    USER_AGENT = "ruby-openid/#{OpenID::Version::VERSION} (#{RUBY_PLATFORM})"

    REDIRECT_LIMIT = 5
    TIMEOUT = ENV["RUBY_OPENID_FETCHER_TIMEOUT"] || 60

    attr_accessor :ca_file, :timeout, :ssl_verify_peer

    # I can fetch through a HTTP proxy; arguments are as for Net::HTTP::Proxy.
    def initialize(proxy_addr = nil, proxy_port = nil,
      proxy_user = nil, proxy_pass = nil)
      @ca_file = nil
      @proxy = Net::HTTP::Proxy(proxy_addr, proxy_port, proxy_user, proxy_pass)
      @timeout = TIMEOUT
      @ssl_verify_peer = nil
    end

    def supports_ssl?(conn)
      conn.respond_to?(:use_ssl=)
    end

    def make_http(uri)
      http = @proxy.new(uri.host, uri.port)
      http.read_timeout = @timeout
      http.open_timeout = @timeout
      http
    end

    def set_verified(conn, verify)
      conn.verify_mode = if verify
        OpenSSL::SSL::VERIFY_PEER
      else
        OpenSSL::SSL::VERIFY_NONE
      end
    end

    def make_connection(uri)
      conn = make_http(uri)

      unless conn.is_a?(Net::HTTP)
        raise format(
          "Expected Net::HTTP object from make_http; got %s",
          conn.class,
        ).to_s
      end

      if uri.scheme == "https"
        raise "SSL support not found; cannot fetch #{uri}" unless supports_ssl?(conn)

        conn.use_ssl = true

        if @ca_file
          set_verified(conn, true)
          conn.ca_file = @ca_file
        elsif @ssl_verify_peer
          set_verified(conn, true)
        else
          Util.log("WARNING: making https request to #{uri} without verifying " +
                   "server certificate; no CA path was specified.")
          set_verified(conn, false)
        end

      end

      conn
    end

    def fetch(url, body = nil, headers = nil, redirect_limit = REDIRECT_LIMIT)
      unparsed_url = url.dup
      url = URI.parse(url)
      raise FetchingError, "Invalid URL: #{unparsed_url}" if url.nil?

      headers ||= {}
      headers["User-agent"] ||= USER_AGENT

      begin
        conn = make_connection(url)
        response = nil

        whole_body = ""
        body_size_limitter = lambda do |r|
          r.read_body do |partial| # read body now
            whole_body << partial
            raise FetchingError.new("Response Too Large") if whole_body.length > MAX_RESPONSE_KB
          end
          whole_body
        end
        response = conn.start do
          # Check the certificate against the URL's hostname
          conn.post_connection_check(url.host) if supports_ssl?(conn) and conn.use_ssl?

          if body.nil?
            conn.request_get(url.request_uri, headers, &body_size_limitter)
          else
            headers["Content-type"] ||= "application/x-www-form-urlencoded"
            conn.request_post(url.request_uri, body, headers, &body_size_limitter)
          end
        end
      rescue Timeout::Error => e
        raise FetchingError, "Error fetching #{url}: #{e}"
      rescue RuntimeError => e
        raise e
      rescue OpenSSL::SSL::SSLError => e
        raise SSLFetchingError, "Error connecting to SSL URL #{url}: #{e}"
      rescue FetchingError => e
        raise e
      rescue Exception => e
        raise FetchingError, "Error fetching #{url}: #{e}"
      end

      case response
      when Net::HTTPRedirection
        if redirect_limit <= 0
          raise HTTPRedirectLimitReached.new(
            "Too many redirects, not fetching #{response["location"]}",
          )
        end
        begin
          fetch(response["location"], body, headers, redirect_limit - 1)
        rescue HTTPRedirectLimitReached => e
          raise e
        rescue FetchingError => e
          raise FetchingError, "Error encountered in redirect from #{url}: #{e}"
        end
      else
        response = HTTPResponse._from_net_response(response, unparsed_url)
        response.body = whole_body
        setup_encoding(response)
        response
      end
    end

    private

    def setup_encoding(response)
      return unless defined?(Encoding.default_external)
      return unless charset = response.type_params["charset"]

      begin
        encoding = Encoding.find(charset)
      rescue ArgumentError
        # NOOP
      end
      encoding ||= Encoding.default_external

      body = response.body
      if body.respond_to?(:force_encoding)
        body.force_encoding(encoding)
      else
        body.set_encoding(encoding)
      end
    end
  end
end
