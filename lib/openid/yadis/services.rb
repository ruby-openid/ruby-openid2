require "openid/yadis/filters"
require "openid/yadis/discovery"
require "openid/yadis/xrds"

module OpenID
  module Yadis
    def self.get_service_endpoints(input_url, flt = nil)
      # Perform the Yadis protocol on the input URL and return an
      # iterable of resulting endpoint objects.
      #
      # @param flt: A filter object or something that is convertable
      # to a filter object (using mkFilter) that will be used to
      # generate endpoint objects. This defaults to generating
      # BasicEndpoint objects.
      result = Yadis.discover(input_url)
      begin
        endpoints = Yadis.apply_filter(
          result.normalized_uri,
          result.response_text,
          flt,
        )
      rescue XRDSError => e
        raise DiscoveryFailure.new(e.to_s, nil)
      end

      [result.normalized_uri, endpoints]
    end

    def self.apply_filter(normalized_uri, xrd_data, flt = nil)
      # Generate an iterable of endpoint objects given this input data,
      # presumably from the result of performing the Yadis protocol.

      flt = Yadis.make_filter(flt)
      et = Yadis.parseXRDS(xrd_data)

      endpoints = []
      each_service(et) do |service_element|
        endpoints += flt.get_service_endpoints(normalized_uri, service_element)
      end

      endpoints
    end
  end
end
