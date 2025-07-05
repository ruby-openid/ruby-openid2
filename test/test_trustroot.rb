# test helpers
require_relative "test_helper"
require_relative "testutil"

# this library
require "ruby-openid2"
require "openid/trustroot"

class TrustRootTest < Minitest::Test
  include OpenID::TestDataMixin

  def _test_sanity(case_, sanity, desc)
    tr = OpenID::TrustRoot::TrustRoot.parse(case_)
    if sanity == "sane"
      refute_nil(tr)
      assert_predicate(tr, :sane?, [case_, desc].join(" "))
      assert(OpenID::TrustRoot::TrustRoot.check_sanity(case_), [case_, desc].join(" "))
    elsif sanity == "insane"
      sanity = tr && tr.sane?

      refute(sanity, [case_, desc, tr&.host, sanity].join(" "))
      refute(OpenID::TrustRoot::TrustRoot.check_sanity(case_), [case_, desc].join(" "))
    else
      assert_nil(tr, case_)
    end
  end

  def _test_match(trust_root, url, expected_match)
    tr = OpenID::TrustRoot::TrustRoot.parse(trust_root)
    actual_match = tr.validate_url(url)
    if expected_match
      assert(actual_match, [trust_root, url].join(" "))
      assert(OpenID::TrustRoot::TrustRoot.check_url(trust_root, url))
    else
      refute(actual_match, [expected_match, actual_match, trust_root, url].join(" "))
      refute(OpenID::TrustRoot::TrustRoot.check_url(trust_root, url))
    end
  end

  def test_trustroots
    data = read_data_file("trustroot.txt", false)

    parts = data.split("=" * 40 + "\n").collect { |i| i.strip }

    assert_equal("", parts[0])
    _, ph, pdat, mh, mdat = parts

    getTests(%w[bad insane sane], ph, pdat).each do |tc|
      sanity, desc, case_ = tc
      _test_sanity(case_, sanity, desc)
    end

    getTests([true, false], mh, mdat).each do |tc|
      match, _, case_ = tc
      trust_root, url = case_.split
      _test_match(trust_root, url, match)
    end
  end

  def getTests(grps, head, dat)
    tests = []
    top = head.strip
    gdat = dat.split("-" * 40 + "\n").collect { |i| i.strip }

    assert_equal("", gdat[0])
    assert_equal(gdat.length, grps.length * 2 + 1)
    i = 1
    grps.each do |x|
      n, desc = gdat[i].split(": ")
      cases = gdat[i + 1].split("\n")

      assert_equal(cases.length, n.to_i, "Number of cases differs from header count")
      cases.each do |case_|
        tests += [[x, top + " - " + desc, case_]]
      end
      i += 2
    end

    tests
  end

  def test_return_to_matches
    data = [
      [[], nil, false],
      [[], "", false],
      [[], "http://bogus/return_to", false],
      [["http://bogus/"], nil, false],
      [["://broken/"], nil, false],
      [["://broken/"], "http://broken/", false],
      [["http://*.broken/"], "http://foo.broken/", false],
      [["http://x.broken/"], "http://foo.broken/", false],
      [["http://first/", "http://second/path/"], "http://second/?query=x", false],

      [["http://broken/"], "http://broken/", true],
      [["http://first/", "http://second/"], "http://second/?query=x", true],
    ]

    data.each do |case_|
      allowed_return_urls, return_to, expected_result = case_
      actual_result = OpenID::TrustRoot.return_to_matches(
        allowed_return_urls,
        return_to,
      )

      assert_equal(expected_result, actual_result)
    end
  end

  def test_build_discovery_url
    data = [
      ["http://foo.com/path", "http://foo.com/path"],
      ["http://foo.com/path?foo=bar", "http://foo.com/path?foo=bar"],
      ["http://*.bogus.com/path", "http://www.bogus.com/path"],
      ["http://*.bogus.com:122/path", "http://www.bogus.com:122/path"],
    ]

    data.each do |case_|
      trust_root, expected_disco_url = case_
      tr = OpenID::TrustRoot::TrustRoot.parse(trust_root)
      actual_disco_url = tr.build_discovery_url

      assert_equal(actual_disco_url, expected_disco_url)
    end
  end
end
