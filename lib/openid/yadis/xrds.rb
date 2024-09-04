require "rexml/document"
require "rexml/element"
require "rexml/xpath"

require "openid/yadis/xri"

module OpenID
  module Yadis
    XRD_NS_2_0 = "xri://$xrd*($v*2.0)"
    XRDS_NS = "xri://$xrds"

    XRDS_NAMESPACES = {
      "xrds" => XRDS_NS,
      "xrd" => XRD_NS_2_0,
    }

    class XRDSError < StandardError; end

    # Raised when there's an assertion in the XRDS that it does not
    # have the authority to make.
    class XRDSFraud < XRDSError
    end

    def self.get_canonical_id(iname, xrd_tree)
      # Return the CanonicalID from this XRDS document.
      #
      # @param iname: the XRI being resolved.
      # @type iname: unicode
      #
      # @param xrd_tree: The XRDS output from the resolver.
      #
      # @returns: The XRI CanonicalID or None.
      # @returntype: unicode or None

      xrd_list = []
      REXML::XPath.match(xrd_tree.root, "/xrds:XRDS/xrd:XRD", XRDS_NAMESPACES).each do |el|
        xrd_list << el
      end

      xrd_list.reverse!

      cid_elements = []

      unless xrd_list.empty?
        xrd_list[0].elements.each do |e|
          next unless e.respond_to?(:name)

          cid_elements << e if e.name == "CanonicalID"
        end
      end

      cid_element = cid_elements[0]

      return unless cid_element

      canonical_id = XRI.make_xri(cid_element.text)

      child_id = canonical_id.downcase

      xrd_list[1..-1].each do |xrd|
        parent_sought = child_id[0...child_id.rindex("!")]

        parent = XRI.make_xri(xrd.elements["CanonicalID"].text)

        if parent_sought != parent.downcase
          raise XRDSFraud.new(format(
            "%s can not come from %s",
            parent_sought,
            parent,
          ))
        end

        child_id = parent_sought
      end

      root = XRI.root_authority(iname)
      unless XRI.provider_is_authoritative(root, child_id)
        raise XRDSFraud.new(format("%s can not come from root %s", child_id, root))
      end

      canonical_id
    end

    class XRDSError < StandardError
    end

    def self.parseXRDS(text)
      disable_entity_expansion do
        raise XRDSError.new("Not an XRDS document.") if text.nil?

        begin
          d = REXML::Document.new(text)
        rescue RuntimeError
          raise XRDSError.new("Not an XRDS document. Failed to parse XML.")
        end

        return d if is_xrds?(d)

        raise XRDSError.new("Not an XRDS document.")
      end
    end

    def self.disable_entity_expansion
      _previous_ = REXML::Document.entity_expansion_limit
      REXML::Document.entity_expansion_limit = 0
      yield
    ensure
      REXML::Document.entity_expansion_limit = _previous_
    end

    def self.is_xrds?(xrds_tree)
      xrds_root = xrds_tree.root
      (!xrds_root.nil? and
        xrds_root.name == "XRDS" and
        xrds_root.namespace == XRDS_NS)
    end

    def self.get_yadis_xrd(xrds_tree)
      REXML::XPath.each(
        xrds_tree.root,
        "/xrds:XRDS/xrd:XRD[last()]",
        XRDS_NAMESPACES,
      ) do |el|
        return el
      end
      raise XRDSError.new("No XRD element found.")
    end

    # aka iterServices in Python
    def self.each_service(xrds_tree, &block)
      xrd = get_yadis_xrd(xrds_tree)
      xrd.each_element("Service", &block)
    end

    def self.services(xrds_tree)
      s = []
      each_service(xrds_tree) do |service|
        s << service
      end
      s
    end

    def self.expand_service(service_element)
      es = service_element.elements
      uris = es.each("URI") { |u| }
      uris = prio_sort(uris)
      types = es.each("Type/text()")
      # REXML::Text objects are not strings.
      types = types.collect { |t| t.to_s }
      uris.collect { |uri| [types, uri.text, service_element] }
    end

    # Sort a list of elements that have priority attributes.
    def self.prio_sort(elements)
      elements.sort do |a, b|
        a.attribute("priority").to_s.to_i <=> b.attribute("priority").to_s.to_i
      end
    end
  end
end
