require "cgi"
require "uri"
require "logger"

# See OpenID::Consumer or OpenID::Server modules, as well as the store classes
module OpenID
  class AssertionError < Exception
  end

  # Exceptions that are raised by the library are subclasses of this
  # exception type, so if you want to catch all exceptions raised by
  # the library, you can catch OpenIDError
  class OpenIDError < StandardError
  end

  module Util
    BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" \
      "abcdefghijklmnopqrstuvwxyz0123456789+/"
    BASE64_RE = Regexp.compile(
      "
    \\A
    ([#{BASE64_CHARS}]{4})*
    ([#{BASE64_CHARS}]{2}==|
     [#{BASE64_CHARS}]{3}=)?
    \\Z",
      Regexp::EXTENDED,
    )

    def self.truthy_assert(value, message = nil)
      return if value

      raise AssertionError, message or value
    end

    def self.to_base64(s)
      [s].pack("m").delete("\n")
    end

    def self.from_base64(s)
      without_newlines = s.gsub(/[\r\n]+/, "")
      raise ArgumentError, "Malformed input: #{s.inspect}" unless BASE64_RE.match(without_newlines)

      without_newlines.unpack1("m")
    end

    def self.urlencode(args)
      a = []
      args.each do |key, val|
        if val.nil?
          val = ""
        elsif !!val == val
          # it's boolean let's convert it to string representation
          # or else CGI::escape won't like it
          val = val.to_s
        end

        a << (CGI.escape(key) + "=" + CGI.escape(val))
      end
      a.join("&")
    end

    def self.parse_query(qs)
      query = {}
      CGI.parse(qs).each { |k, v| query[k] = v[0] }
      query
    end

    def self.append_args(url, args)
      url = url.dup
      return url if args.length == 0

      args = args.sort if args.respond_to?(:each_pair)

      url << (url.include?("?") ? "&" : "?")
      url << Util.urlencode(args)
    end

    @@logger = Logger.new(STDERR)
    @@logger.progname = "OpenID"

    def self.logger=(logger)
      @@logger = logger
    end

    def self.logger
      @@logger
    end

    # change the message below to do whatever you like for logging
    def self.log(message)
      logger.info(message)
    end

    def self.auto_submit_html(form, title = "OpenID transaction in progress")
      "
<html>
<head>
  <title>#{title}</title>
</head>
<body onload='document.forms[0].submit();'>
#{form}
<script>
var elements = document.forms[0].elements;
for (var i = 0; i < elements.length; i++) {
  elements[i].style.display = \"none\";
}
</script>
</body>
</html>
"
    end

    ESCAPE_TABLE = {"&" => "&amp;", "<" => "&lt;", ">" => "&gt;", '"' => "&quot;", "'" => "&#039;"}
    # Modified from ERb's html_encode
    def self.html_encode(str)
      str.to_s.gsub(/[&<>"']/) { |s| ESCAPE_TABLE[s] }
    end
  end
end
