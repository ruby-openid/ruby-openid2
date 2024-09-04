require_relative "../fetchers"

module OpenID
  module Yadis
    module XRI
      # The '(' is for cross-reference authorities, and hopefully has a
      # matching ')' somewhere.
      XRI_AUTHORITIES = ["!", "=", "@", "+", "$", "("]

      def self.identifier_scheme(identifier)
        if !identifier.nil? and
            identifier.length > 0 and
            (identifier.match("^xri://") or
             XRI_AUTHORITIES.member?(identifier[0].chr))
          :xri
        else
          :uri
        end
      end

      # Transform an XRI reference to an IRI reference.  Note this is
      # not not idempotent, so do not apply this to an identifier more
      # than once.  XRI Syntax section 2.3.1
      def self.to_iri_normal(xri)
        iri = xri.dup
        iri.insert(0, "xri://") unless iri.match?("^xri://")
        escape_for_iri(iri)
      end

      # Note this is not not idempotent, so do not apply this more than
      # once.  XRI Syntax section 2.3.2
      def self.escape_for_iri(xri)
        esc = xri.dup
        # encode all %
        esc.gsub!("%", "%25")
        esc.gsub!(/\((.*?)\)/) do |xref_match|
          xref_match.gsub(%r{[/?\#]}) do |char_match|
            CGI.escape(char_match)
          end
        end
        esc
      end

      # Transform an XRI reference to a URI reference.  Note this is not
      # not idempotent, so do not apply this to an identifier more than
      # once.  XRI Syntax section 2.3.1
      def self.to_uri_normal(xri)
        iri_to_uri(to_iri_normal(xri))
      end

      # RFC 3987 section 3.1
      def self.iri_to_uri(iri)
        iri.dup
        # for char in ucschar or iprivate
        # convert each char to %HH%HH%HH (as many %HH as octets)
      end

      def self.provider_is_authoritative(provider_id, canonical_id)
        lastbang = canonical_id.rindex("!")
        return false unless lastbang

        parent = canonical_id[0...lastbang]
        parent == provider_id
      end

      def self.root_authority(xri)
        xri = xri[6..-1] if xri.index("xri://") == 0
        authority = xri.split("/", 2)[0]
        root = if authority[0].chr == "("
          authority[0...authority.index(")") + 1]
        elsif XRI_AUTHORITIES.member?(authority[0].chr)
          authority[0].chr
        else
          authority.split(/[!*]/)[0]
        end

        make_xri(root)
      end

      def self.make_xri(xri)
        xri = "xri://" + xri if xri.index("xri://") != 0
        xri
      end
    end
  end
end
