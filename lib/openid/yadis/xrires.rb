require 'cgi'
require 'openid/yadis/xri'
require 'openid/yadis/xrds'
require 'openid/fetchers'

module OpenID
  module Yadis
    module XRI
      class XRIHTTPError < StandardError; end

      class ProxyResolver
        DEFAULT_PROXY = 'http://proxy.xri.net/'

        def initialize(proxy_url = nil)
          @proxy_url = proxy_url || DEFAULT_PROXY

          @proxy_url += '/' unless @proxy_url.match('/$')
        end

        def query_url(xri, service_type = nil)
          # URI normal form has a leading xri://, but we need to strip
          # that off again for the QXRI.  This is under discussion for
          # XRI Resolution WD 11.
          qxri = XRI.to_uri_normal(xri)[6..-1]
          hxri = @proxy_url + qxri
          args = { '_xrd_r' => 'application/xrds+xml' }
          if service_type
            args['_xrd_t'] = service_type
          else
            # don't perform service endpoint selection
            args['_xrd_r'] += ';sep=false'
          end

          XRI.append_args(hxri, args)
        end

        def query(xri)
          # these can be query args or http headers, needn't be both.
          # headers = {'Accept' => 'application/xrds+xml;sep=true'}
          url = query_url(xri)
          begin
            response = OpenID.fetch(url)
          rescue StandardError
            raise XRIHTTPError, "Could not fetch #{xri}, #{$!}"
          end
          raise XRIHTTPError, "Could not fetch #{xri}" if response.nil?

          xrds = Yadis.parseXRDS(response.body)
          canonicalID = Yadis.get_canonical_id(xri, xrds)

          [canonicalID, Yadis.services(xrds)]
          # TODO:
          #  * If we do get hits for multiple service_types, we're almost
          #    certainly going to have duplicated service entries and
          #    broken priority ordering.
        end
      end

      def self.urlencode(args)
        a = []
        args.each do |key, val|
          a << (CGI.escape(key) + '=' + CGI.escape(val))
        end
        a.join('&')
      end

      def self.append_args(url, args)
        return url if args.empty?

        # rstrip question marks
        rstripped = url.dup
        rstripped = rstripped[0...rstripped.length - 1] while rstripped[-1].chr == '?'

        sep = if rstripped.index('?')
                '&'
              else
                '?'
              end

        url + sep + XRI.urlencode(args)
      end
    end
  end
end
