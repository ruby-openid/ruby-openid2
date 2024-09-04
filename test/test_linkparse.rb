require_relative "test_helper"
require_relative "testutil"
require "openid/consumer/html_parse"

class LinkParseTestCase < Minitest::Test
  include OpenID::TestDataMixin

  def attr_cmp(expected, found)
    e = expected.to_a.sort
    f = found.to_a.sort
    while (ep = e.shift)
      ek, ev = ep
      fk, fv = f.shift
      ok = false
      while ek[-1] == "*"[0] # optional entry detected
        if fk == ek[0...-1] and fv == ev # optional entry found
          ok = true
          break
        else # not found. okay, move on to next expected pair
          ek, ev = e.shift
        end
        next unless ek.nil?

        ok = true if fk.nil?
        break
      end
      next if ok
      next if fk == ek and fv == ev

      return false
    end
    f.empty?
  end

  def test_attrcmp
    good = [
      [{"foo" => "bar"}, {"foo" => "bar"}],
      [{"foo*" => "bar"}, {"foo" => "bar"}],
      [{"foo" => "bar", "bam*" => "baz"}, {"foo" => "bar"}],
      [
        {"foo" => "bar", "bam*" => "baz", "tak" => "tal"},
        {"foo" => "bar", "tak" => "tal"},
      ],
    ]
    bad = [
      [{}, {"foo" => "bar"}],
      [{"foo" => "bar"}, {"bam" => "baz"}],
      [{"foo" => "bar"}, {}],
      [{"foo*" => "bar"}, {"foo*" => "bar"}],
      [{"foo" => "bar", "tak" => "tal"}, {"foo" => "bar"}],
    ]

    good.each { |c| assert(attr_cmp(c[0], c[1]), c.inspect) }
    bad.each { |c| assert(!attr_cmp(c[0], c[1]), c.inspect) }
  end

  def test_linkparse
    cases = read_data_file("linkparse.txt", false).split("\n\n\n")

    numtests = nil
    testnum = 0
    cases.each do |c|
      headers, html = c.split("\n\n", 2)
      expected_links = []
      name = ""
      testnum += 1
      headers.split("\n").each do |h|
        k, v = h.split(":", 2)
        v = "" if v.nil?
        if k == "Num Tests"
          assert_nil(numtests, "datafile parsing error: there can be only one NumTests")
          numtests = v.to_i
          testnum = 0
          next
        elsif k == "Name"
          name = v.strip
        elsif ["Link", "Link*"].include?(k)
          attrs = {}
          v.strip.split.each do |a|
            kk, vv = a.split("=")
            attrs[kk] = vv
          end
          expected_links << [k == "Link*", attrs]
        else
          assert(false, "datafile parsing error: bad header #{h}")
        end
      end
      html = html.force_encoding("UTF-8") if html.respond_to?(:force_encoding)
      links = OpenID.parse_link_attrs(html)

      found = links.dup
      expected = expected_links.dup
      while (fl = found.shift)
        optional, el = expected.shift
        optional, el = expected.shift while optional and !attr_cmp(el, fl) and !expected.empty?

        assert(attr_cmp(el, fl), "#{name}: #{fl.inspect} does not match #{el.inspect}")
      end
    end

    assert_equal(numtests, testnum, "Number of tests")

    # test handling of invalid UTF-8 byte sequences
    html = if "".respond_to?(:force_encoding)
      "<html><body>hello joel\255</body></html>".force_encoding("UTF-8")
    else
      "<html><body>hello joel\255</body></html>"
    end
    OpenID.parse_link_attrs(html)
  end
end
