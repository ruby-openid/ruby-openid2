# test helpers
require_relative "test_helper"

# this library
require "ruby-openid2"
require "openid/consumer/discovery"
require "openid/yadis/services"

module OpenID
  XRDS_BOILERPLATE = <<~EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <xrds:XRDS xmlns:xrds="xri://$xrds"
               xmlns="xri://$xrd*($v*2.0)"
               xmlns:openid="http://openid.net/xmlns/1.0">
        <XRD>
    %s
        </XRD>
    </xrds:XRDS>
  EOF

  def self.mkXRDS(services)
    format(XRDS_BOILERPLATE, services)
  end

  def self.mkService(uris = nil, type_uris = nil, local_id = nil, dent = "        ")
    chunks = [dent, "<Service>\n"]
    dent2 = dent + "    "
    if type_uris
      type_uris.each do |type_uri|
        chunks += [dent2 + "<Type>", type_uri, "</Type>\n"]
      end
    end

    if uris
      uris.each do |uri|
        if uri.is_a?(Array)
          uri, prio = uri
        else
          prio = nil
        end

        chunks += [dent2, "<URI"]
        chunks += [" priority='", str(prio), "'"] unless prio.nil?
        chunks += [">", uri, "</URI>\n"]
      end
    end

    chunks += [dent2, "<openid:Delegate>", local_id, "</openid:Delegate>\n"] if local_id

    chunks += [dent, "</Service>\n"]

    chunks.join("")
  end

  # Different sets of server URLs for use in the URI tag
  SERVER_URL_OPTIONS = [
    [], # This case should not generate an endpoint object
    ["http://server.url/"],
    ["https://server.url/"],
    ["https://server.url/", "http://server.url/"],
    [
      "https://server.url/",
      "http://server.url/",
      "http://example.server.url/",
    ],
  ]

  # Used for generating test data
  def self.subsets(l)
    subsets_list = [[]]
    l.each do |x|
      subsets_list += subsets_list.collect { |t| [x] + t }
    end

    subsets_list
  end

  # A couple of example extension type URIs. These are not at all
  # official, but are just here for testing.
  EXT_TYPES = [
    "http://janrain.com/extension/blah",
    "http://openid.net/sreg/1.0",
  ]

  # Range of valid Delegate tag values for generating test data
  LOCAL_ID_OPTIONS = [
    nil,
    "http://vanity.domain/",
    "https://somewhere/yadis/",
  ]

  class OpenIDYadisTest
    def initialize(uris, type_uris, local_id)
      super()
      @uris = uris
      @type_uris = type_uris
      @local_id = local_id

      @yadis_url = "http://unit.test/"

      # Create an XRDS document to parse
      services = OpenID.mkService(
        @uris,
        @type_uris,
        @local_id,
      )
      @xrds = OpenID.mkXRDS(services)
    end

    def runTest(testcase)
      # Parse into endpoint objects that we will check
      endpoints = Yadis.apply_filter(@yadis_url, @xrds, OpenIDServiceEndpoint)

      # make sure there are the same number of endpoints as URIs. This
      # assumes that the type_uris contains at least one OpenID type.
      testcase.assert_equal(@uris.length, endpoints.length)

      # So that we can check equality on the endpoint types
      type_uris = @type_uris.dup
      type_uris.sort!

      seen_uris = []
      endpoints.each do |endpoint|
        seen_uris << endpoint.server_url

        # All endpoints will have same yadis_url
        testcase.assert_equal(@yadis_url, endpoint.claimed_id)

        # and local_id
        if @local_id.nil?
          testcase.assert_nil(endpoint.local_id)
        else
          testcase.assert_equal(@local_id, endpoint.local_id)
        end

        # and types
        actual_types = endpoint.type_uris.dup
        actual_types.sort!

        testcase.assert_equal(type_uris, actual_types, actual_types.inspect)
      end

      # So that they will compare equal, because we don't care what
      # order they are in
      seen_uris.sort!
      uris = @uris.dup
      uris.sort!

      # Make sure we saw all URIs, and saw each one once
      testcase.assert_equal(uris, seen_uris)
    end
  end

  class OpenIDYadisTests < Minitest::Test
    def test_openid_yadis
      data = []

      # All valid combinations of Type tags that should produce an
      # OpenID endpoint
      type_uri_options = []

      OpenID.subsets([OPENID_1_0_TYPE, OPENID_1_1_TYPE]).each do |ts|
        OpenID.subsets(EXT_TYPES).each do |exts|
          type_uri_options << exts + ts unless ts.empty?
        end
      end

      # All combinations of valid URIs, Type URIs and Delegate tags
      SERVER_URL_OPTIONS.each do |uris|
        type_uri_options.each do |type_uris|
          LOCAL_ID_OPTIONS.each do |local_id|
            data << [uris, type_uris, local_id]
          end
        end
      end

      data.each do |args|
        t = OpenIDYadisTest.new(*args)
        t.runTest(self)
      end
    end
  end
end
