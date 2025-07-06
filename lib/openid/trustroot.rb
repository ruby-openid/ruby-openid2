# stdlib
require "uri"

# This library
require_relative "urinorm"

module OpenID
  class RealmVerificationRedirected < Exception
    # Attempting to verify this realm resulted in a redirect.
    def initialize(relying_party_url, rp_url_after_redirects)
      @relying_party_url = relying_party_url
      @rp_url_after_redirects = rp_url_after_redirects
    end

    def to_s
      "Attempting to verify #{@relying_party_url} resulted in " +
        "redirect to #{@rp_url_after_redirects}"
    end
  end

  module TrustRoot
    TOP_LEVEL_DOMAINS = %w[
      ac
      ad
      ae
      aero
      af
      ag
      ai
      al
      am
      an
      ao
      aq
      ar
      arpa
      as
      asia
      at
      au
      aw
      ax
      az
      ba
      bb
      bd
      be
      bf
      bg
      bh
      bi
      biz
      bj
      bm
      bn
      bo
      br
      bs
      bt
      bv
      bw
      by
      bz
      ca
      cat
      cc
      cd
      cf
      cg
      ch
      ci
      ck
      cl
      cm
      cn
      co
      com
      coop
      cr
      cu
      cv
      cx
      cy
      cz
      de
      dj
      dk
      dm
      do
      dz
      ec
      edu
      ee
      eg
      er
      es
      et
      eu
      fi
      fj
      fk
      fm
      fo
      fr
      ga
      gb
      gd
      ge
      gf
      gg
      gh
      gi
      gl
      gm
      gn
      gov
      gp
      gq
      gr
      gs
      gt
      gu
      gw
      gy
      hk
      hm
      hn
      hr
      ht
      hu
      id
      ie
      il
      im
      in
      info
      int
      io
      iq
      ir
      is
      it
      je
      jm
      jo
      jobs
      jp
      ke
      kg
      kh
      ki
      km
      kn
      kp
      kr
      kw
      ky
      kz
      la
      lb
      lc
      li
      lk
      lr
      ls
      lt
      lu
      lv
      ly
      ma
      mc
      md
      me
      mg
      mh
      mil
      mk
      ml
      mm
      mn
      mo
      mobi
      mp
      mq
      mr
      ms
      mt
      mu
      museum
      mv
      mw
      mx
      my
      mz
      na
      name
      nc
      ne
      net
      nf
      ng
      ni
      nl
      no
      np
      nr
      nu
      nz
      om
      org
      pa
      pe
      pf
      pg
      ph
      pk
      pl
      pm
      pn
      pr
      pro
      ps
      pt
      pw
      py
      qa
      re
      ro
      rs
      ru
      rw
      sa
      sb
      sc
      sd
      se
      sg
      sh
      si
      sj
      sk
      sl
      sm
      sn
      so
      sr
      st
      su
      sv
      sy
      sz
      tc
      td
      tel
      tf
      tg
      th
      tj
      tk
      tl
      tm
      tn
      to
      tp
      tr
      travel
      tt
      tv
      tw
      tz
      ua
      ug
      uk
      us
      uy
      uz
      va
      vc
      ve
      vg
      vi
      vn
      vu
      wf
      ws
      xn--0zwm56d
      xn--11b5bs3a9aj6g
      xn--80akhbyknj4f
      xn--9t4b11yi5a
      xn--deba0ad
      xn--g6w251d
      xn--hgbk6aj7f53bba
      xn--hlcj6aya9esc7a
      xn--jxalpdlp
      xn--kgbechtv
      xn--zckzah
      ye
      yt
      yu
      za
      zm
      zw
    ]

    ALLOWED_PROTOCOLS = %w[http https]

    # The URI for relying party discovery, used in realm verification.
    #
    # XXX: This should probably live somewhere else (like in
    # OpenID or OpenID::Yadis somewhere)
    RP_RETURN_TO_URL_TYPE = "http://specs.openid.net/auth/2.0/return_to"

    # If the endpoint is a relying party OpenID return_to endpoint,
    # return the endpoint URL. Otherwise, return None.
    #
    # This function is intended to be used as a filter for the Yadis
    # filtering interface.
    #
    # endpoint: An XRDS BasicServiceEndpoint, as returned by
    # performing Yadis dicovery.
    #
    # returns the endpoint URL or None if the endpoint is not a
    # relying party endpoint.
    def self._extract_return_url(endpoint)
      return endpoint.uri if endpoint.matchTypes([RP_RETURN_TO_URL_TYPE])

      nil
    end

    # Is the return_to URL under one of the supplied allowed
    # return_to URLs?
    def self.return_to_matches(allowed_return_to_urls, return_to)
      allowed_return_to_urls.each do |allowed_return_to|
        # A return_to pattern works the same as a realm, except that
        # it's not allowed to use a wildcard. We'll model this by
        # parsing it as a realm, and not trying to match it if it has
        # a wildcard.

        return_realm = TrustRoot.parse(allowed_return_to)
        if !return_realm.nil? and

            # Does not have a wildcard
            !return_realm.wildcard and

            # Matches the return_to that we passed in with it
            return_realm.validate_url(return_to) # Parses as a trust root

          return true
        end
      end

      # No URL in the list matched
      false
    end

    # Given a relying party discovery URL return a list of return_to
    # URLs.
    def self.get_allowed_return_urls(relying_party_url)
      rp_url_after_redirects, return_to_urls = services.get_service_endpoints(
        relying_party_url, _extract_return_url
      )

      if rp_url_after_redirects != relying_party_url
        # Verification caused a redirect
        raise RealmVerificationRedirected.new(
          relying_party_url, rp_url_after_redirects
        )
      end

      return_to_urls
    end

    # Verify that a return_to URL is valid for the given realm.
    #
    # This function builds a discovery URL, performs Yadis discovery
    # on it, makes sure that the URL does not redirect, parses out
    # the return_to URLs, and finally checks to see if the current
    # return_to URL matches the return_to.
    #
    # raises DiscoveryFailure when Yadis discovery fails returns
    # true if the return_to URL is valid for the realm
    def self.verify_return_to(realm_str, return_to, _vrfy = nil)
      # _vrfy parameter is there to make testing easier
      _vrfy = method(:get_allowed_return_urls) if _vrfy.nil?

      raise ArgumentError, "_vrfy must be a Proc or Method" unless _vrfy.is_a?(Proc) or _vrfy.is_a?(Method)

      realm = TrustRoot.parse(realm_str)
      if realm.nil?
        # The realm does not parse as a URL pattern
        return false
      end

      begin
        allowable_urls = _vrfy.call(realm.build_discovery_url)
      rescue RealmVerificationRedirected => e
        Util.log(e.to_s)
        return false
      end

      return true if return_to_matches(allowable_urls, return_to)

      Util.log("Failed to validate return_to #{return_to} for " +
          "realm #{realm_str}, was not in #{allowable_urls}")
      false
    end

    class TrustRoot
      attr_reader :unparsed, :proto, :wildcard, :host, :port, :path

      EMPTY_RE = Regexp.new('^http[s]?:\/\/\*\/$').freeze

      class << self
        def _build_path(path, query = nil, frag = nil)
          s = path.dup

          frag = nil if frag == ""
          query = nil if query == ""

          s << "?" << query if query

          s << "#" << frag if frag

          s
        end

        def _parse_url(url)
          begin
            url = URINorm.urinorm(url)
          rescue URI::InvalidURIError
            nil
          end

          begin
            parsed = URI::DEFAULT_PARSER.parse(url)
          rescue URI::InvalidURIError
            return
          end

          path = TrustRoot._build_path(
            parsed.path,
            parsed.query,
            parsed.fragment,
          )

          [
            parsed.scheme || "",
            parsed.host || "",
            parsed.port || "",
            path || "",
          ]
        end

        def parse(trust_root)
          trust_root = trust_root.dup
          unparsed = trust_root.dup

          # look for wildcard
          wildcard = !trust_root.index("://*.").nil?
          trust_root.sub!("*.", "") if wildcard
          # handle http://*/ case
          if !wildcard and EMPTY_RE.match(trust_root)
            proto = trust_root.split(":")[0]
            port = (proto == "http") ? 80 : 443
            return new(unparsed, proto, true, "", port, "/")
          end

          parts = TrustRoot._parse_url(trust_root)
          return if parts.nil?

          proto, host, port, path = parts
          return if host[0] == "."

          # check for URI fragment
          return if path and !path.index("#").nil?

          return unless %w[http https].member?(proto)

          new(unparsed, proto, wildcard, host, port, path)
        end

        def check_sanity(trust_root_string)
          trust_root = TrustRoot.parse(trust_root_string)
          return false if trust_root.nil?

          trust_root.sane?
        end

        # quick func for validating a url against a trust root.  See the
        # TrustRoot class if you need more control.
        def check_url(trust_root, url)
          tr = parse(trust_root)
          (!tr.nil? and tr.validate_url(url))
        end
      end

      # Return a discovery URL for this realm.
      #
      # This function does not check to make sure that the realm is
      # valid. Its behaviour on invalid inputs is undefined.
      #
      # return_to:: The relying party return URL of the OpenID
      # authentication request
      #
      # Returns the URL upon which relying party discovery should be
      # run in order to verify the return_to URL
      def build_discovery_url
        return @unparsed unless wildcard

        # Use "www." in place of the star
        www_domain = "www." + @host
        port = (!@port.nil? and ![80, 443].member?(@port)) ? (":" + @port.to_s) : ""
        "#{@proto}://#{www_domain}#{port}#{@path}"
      end

      def initialize(unparsed, proto, wildcard, host, port, path)
        @unparsed = unparsed
        @proto = proto
        @wildcard = wildcard
        @host = host
        @port = port
        @path = path
      end

      def sane?
        return false if @host.nil? || @host.empty?
        return true if @host == "localhost"

        host_parts = @host.split(".")

        # a note: Something changed in the way Ruby parsed URIs,
        #   where it used to be very strict (probably incorrectly so),
        #   and now it is much more permissive (and probably more standards compliant).
        # Handle cases Ruby used to consider "insane" here to prevent them from being considered "sane".
        wild_check = host_parts[-2, 2]
        return false if wild_check&.detect { |wild| wild["*"] }

        # a note: ruby string split does not put an empty string at
        # the end of the list if the split element is last.  for
        # example, 'foo.com.'.split('.') => ['foo','com'].  Mentioned
        # because the python code differs here.

        return false if host_parts.length == 0

        # no adjacent dots
        return false if host_parts.member?("")

        # last part must be a tld
        tld = host_parts[-1]
        return false unless TOP_LEVEL_DOMAINS.member?(tld)

        return false if host_parts.length == 1

        if @wildcard && (tld.length == 2 and host_parts[-2].length <= 3)
          # It's a 2-letter tld with a short second to last segment
          # so there needs to be more than two segments specified
          # (e.g. *.co.uk is insane)
          return host_parts.length > 2
        end

        true
      end

      def validate_url(url)
        parts = TrustRoot._parse_url(url)
        return false if parts.nil?

        proto, host, port, path = parts

        return false unless proto == @proto
        return false unless port == @port
        return false unless host.index("*").nil?

        if !@wildcard
          return false if host != @host
        elsif (@host != "") and
            !host.end_with?("." + @host) and
            (host != @host)
          return false
        end

        if path != @path
          path_len = @path.length
          trust_prefix = @path[0...path_len]
          url_prefix = path[0...path_len]

          # must be equal up to the length of the path, at least
          return false if trust_prefix != url_prefix

          # These characters must be on the boundary between the end
          # of the trust root's path and the start of the URL's path.
          allowed = if !@path.index("?").nil?
            "&"
          else
            "?/"
          end

          return (!allowed.index(@path[-1]).nil? or
                  !allowed.index(path[path_len]).nil?)
        end

        true
      end
    end
  end
end
