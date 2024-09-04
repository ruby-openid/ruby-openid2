require "openid/yadis/htmltokenizer"

module OpenID
  # Stuff to remove before we start looking for tags
  REMOVED_RE = %r{
    # Comments
    <!--.*?-->

    # CDATA blocks
  | <!\[CDATA\[.*?\]\]>

    # script blocks
  | <script\b

    # make sure script is not an XML namespace
    (?!:)

    [^>]*>.*?</script>

  }mix

  def self.openid_unescape(s)
    s.gsub("&amp;", "&").gsub("&lt;", "<").gsub("&gt;", ">").gsub("&quot;", '"')
  end

  def self.unescape_hash(h)
    newh = {}
    h.map do |k, v|
      newh[k] = openid_unescape(v)
    end
    newh
  end

  def self.parse_link_attrs(html)
    begin
      stripped = html.gsub(REMOVED_RE, "")
    rescue ArgumentError
      begin
        stripped = html.encode("UTF-8", "binary", invalid: :replace, undef: :replace, replace: "").gsub(
          REMOVED_RE, ""
        )
      rescue Encoding::UndefinedConversionError, Encoding::ConverterNotFoundError
        # needed for a problem in JRuby where it can't handle the conversion.
        # see details here: https://github.com/jruby/jruby/issues/829
        stripped = html.encode("UTF-8", "ASCII", invalid: :replace, undef: :replace, replace: "").gsub(
          REMOVED_RE, ""
        )
      end
    end
    parser = HTMLTokenizer.new(stripped)

    links = []
    # to keep track of whether or not we are in the head element
    in_head = false
    in_html = false
    saw_head = false

    begin
      while el = parser.getTag(
        "head",
        "/head",
        "link",
        "body",
        "/body",
        "html",
        "/html",
      )

        # we are leaving head or have reached body, so we bail
        return links if ["/head", "body", "/body", "/html"].member?(el.tag_name)

        # enforce html > head > link
        in_html = true if el.tag_name == "html"
        next unless in_html

        if el.tag_name == "head"
          if saw_head
            return links # only allow one head
          end

          saw_head = true
          in_head = true unless el.to_s[-2] == 47 # tag ends with a /: a short tag
        end
        next unless in_head

        return links if el.tag_name == "html"

        links << unescape_hash(el.attr_hash) if el.tag_name == "link"

      end
    rescue Exception # just stop parsing if there's an error
    end
    links
  end

  def self.rel_matches(rel_attr, target_rel)
    # Does this target_rel appear in the rel_str?
    # XXX: TESTME
    rels = rel_attr.strip.split
    rels.each do |rel|
      rel = rel.downcase
      return true if rel == target_rel
    end

    false
  end

  def self.link_has_rel(link_attrs, target_rel)
    # Does this link have target_rel as a relationship?

    # XXX: TESTME
    rel_attr = link_attrs["rel"]
    (rel_attr and rel_matches(rel_attr, target_rel))
  end

  def self.find_links_rel(link_attrs_list, target_rel)
    # Filter the list of link attributes on whether it has target_rel
    # as a relationship.

    # XXX: TESTME
    matches_target = ->(attrs) { link_has_rel(attrs, target_rel) }
    result = []

    link_attrs_list.each do |item|
      result << item if matches_target.call(item)
    end

    result
  end

  def self.find_first_href(link_attrs_list, target_rel)
    # Return the value of the href attribute for the first link tag in
    # the list that has target_rel as a relationship.

    # XXX: TESTME
    matches = find_links_rel(link_attrs_list, target_rel)
    return if !matches or matches.empty?

    first = matches[0]
    first["href"]
  end
end
