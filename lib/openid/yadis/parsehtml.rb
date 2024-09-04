# stdlib
require "cgi"

# This library
require_relative "htmltokenizer"

module OpenID
  module Yadis
    def self.html_yadis_location(html)
      parser = HTMLTokenizer.new(html)

      # to keep track of whether or not we are in the head element
      in_head = false

      begin
        while el = parser.getTag(
          "head",
          "/head",
          "meta",
          "body",
          "/body",
          "html",
          "script",
        )

          # we are leaving head or have reached body, so we bail
          return if ["/head", "body", "/body"].member?(el.tag_name)

          if el.tag_name == "head" && !(el.to_s[-2] == "/")
            in_head = true # tag ends with a /: a short tag
          end
          next unless in_head

          if el.tag_name == "script" && !(el.to_s[-2] == "/")
            parser.getTag("/script") # tag ends with a /: a short tag
          end

          return if el.tag_name == "html"

          next unless el.tag_name == "meta" and (equiv = el.attr_hash["http-equiv"])
          if %w[x-xrds-location x-yadis-location].member?(equiv.downcase) &&
              el.attr_hash.member?("content")
            return CGI.unescapeHTML(el.attr_hash["content"])
          end
        end
      rescue HTMLTokenizerError # just stop parsing if there's an error
      end
    end
  end
end
