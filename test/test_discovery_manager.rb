# test helpers
require_relative "test_helper"
require_relative "testutil"

# this library
require "openid"
require "openid/consumer"

module OpenID
  class TestDiscoveredServices < Minitest::Test
    def setup
      @starting_url = "http://starting.url.com/"
      @yadis_url = "http://starting.url.com/xrds"
      @services = %w[bogus not_a_service]

      @disco_services = Consumer::DiscoveredServices.new(
        @starting_url,
        @yadis_url,
        @services.dup,
      )
    end

    def test_next
      assert_equal(@disco_services.next, @services[0])
      assert_equal(@disco_services.current, @services[0])

      assert_equal(@disco_services.next, @services[1])
      assert_equal(@disco_services.current, @services[1])

      assert_nil(@disco_services.next)
      assert_nil(@disco_services.current)
    end

    def test_for_url
      assert(@disco_services.for_url?(@starting_url))
      assert(@disco_services.for_url?(@yadis_url))

      assert(!@disco_services.for_url?(nil))
      assert(!@disco_services.for_url?("invalid"))
    end

    def test_started
      assert(!@disco_services.started?)
      @disco_services.next

      assert_predicate(@disco_services, :started?)
      @disco_services.next

      assert_predicate(@disco_services, :started?)
      @disco_services.next

      assert(!@disco_services.started?)
    end

    def test_empty
      assert_empty(Consumer::DiscoveredServices.new(nil, nil, []))

      assert(!@disco_services.empty?)

      @disco_services.next
      @disco_services.next

      assert_predicate(@disco_services, :started?)
    end
  end

  # I need to be able to test the protected methods; this lets me do
  # that.
  class PassthroughDiscoveryManager < Consumer::DiscoveryManager
    def method_missing(m, *args)
      method(m).call(*args)
    end
  end

  class TestDiscoveryManager < Minitest::Test
    def setup
      session = {}
      @session = OpenID::Consumer::Session.new(session, OpenID::Consumer::DiscoveredServices)
      @url = "http://unittest.com/"
      @key_suffix = "testing"
      @yadis_url = "http://unittest.com/xrds"
      @manager = PassthroughDiscoveryManager.new(session, @url, @key_suffix)
      @key = @manager.session_key
    end

    def test_construct
      # Make sure the default session key suffix is not nil.
      m = Consumer::DiscoveryManager.new(nil, nil)

      assert(!m.instance_variable_get(:@session_key_suffix).nil?)

      m = Consumer::DiscoveryManager.new(nil, nil, "override")

      assert_equal("override", m.instance_variable_get(:@session_key_suffix))
    end

    def test_get_next_service
      assert_nil(@session[@key])

      next_service = @manager.get_next_service do
        [@yadis_url, %w[one two three]]
      end

      disco = @session[@key]

      assert_equal("one", disco.current)
      assert_equal("one", next_service)
      assert(disco.for_url?(@url))
      assert(disco.for_url?(@yadis_url))

      # The first two calls to get_next_service should return the
      # services in @disco.
      assert_equal("two", @manager.get_next_service)
      assert_equal("three", @manager.get_next_service)
      disco = @session[@key]

      assert_equal("three", disco.current)

      # The manager is exhausted and should be deleted and a new one
      # should be created.
      @manager.get_next_service do
        [@yadis_url, ["four"]]
      end

      disco2 = @session[@key]

      assert_equal("four", disco2.current)

      # create_manager may return a nil manager, in which case the
      # next service should be nil.
      @manager.extend(OpenID::InstanceDefExtension)
      @manager.instance_def(:create_manager) do |_yadis_url, _services|
        nil
      end

      result = @manager.get_next_service do |_url|
        ["unused", []]
      end

      assert_nil(result)
    end

    def test_cleanup
      # With no preexisting manager, cleanup() returns nil.
      assert_nil(@manager.cleanup)

      # With a manager, it returns the manager's current service.
      disco = Consumer::DiscoveredServices.new(@url, @yadis_url, %w[one two])

      @session[@key] = disco

      assert_nil(@manager.cleanup)
      assert_nil(@session[@key])

      disco.next
      @session[@key] = disco

      assert_equal("one", @manager.cleanup)
      assert_nil(@session[@key])

      # The force parameter should be passed through to get_manager
      # and destroy_manager.
      force_value = "yo"
      testcase = self

      m = Consumer::DiscoveredServices.new(nil, nil, ["inner"])
      m.next

      @manager.extend(OpenID::InstanceDefExtension)
      @manager.instance_def(:get_manager) do |force|
        testcase.assert_equal(force, force_value)
        m
      end

      @manager.instance_def(:destroy_manager) do |force|
        testcase.assert_equal(force, force_value)
      end

      assert_equal("inner", @manager.cleanup(force_value))
    end

    def test_get_manager
      # get_manager should always return the loaded manager when
      # forced.
      @session[@key] = "bogus"

      assert_equal("bogus", @manager.get_manager(true))

      # When not forced, only managers for @url should be returned.
      disco = Consumer::DiscoveredServices.new(@url, @yadis_url, ["one"])
      @session[@key] = disco

      assert_equal(@manager.get_manager, disco)

      # Try to get_manager for a manger that doesn't manage @url:
      disco2 = Consumer::DiscoveredServices.new(
        "http://not.this.url.com/",
        "http://other.yadis.url/",
        ["one"],
      )
      @session[@key] = disco2

      assert_nil(@manager.get_manager)
      assert_equal(@manager.get_manager(true), disco2)
    end

    def test_create_manager
      assert_nil(@session[@key])

      services = %w[created manager]
      returned_disco = @manager.create_manager(@yadis_url, services)

      stored_disco = @session[@key]

      assert_equal(stored_disco, returned_disco)

      assert(stored_disco.for_url?(@yadis_url))
      assert_equal("created", stored_disco.next)

      # Calling create_manager with a preexisting manager should
      # result in StandardError.
      assert_raises(StandardError) do
        @manager.create_manager(@yadis_url, services)
      end

      # create_manager should do nothing (and return nil) if given no
      # services.
      @session[@key] = nil
      result = @manager.create_manager(@yadis_url, [])

      assert_nil(result)
      assert_nil(@session[@key])
    end

    class DestroyCalledException < StandardError; end

    def test_destroy_manager
      # destroy_manager should remove the manager from the session,
      # forcibly if necessary.
      valid_disco = Consumer::DiscoveredServices.new(@url, @yadis_url, ["serv"])
      invalid_disco = Consumer::DiscoveredServices.new(
        "http://not.mine.com/",
        "http://different.url.com/",
        ["serv"],
      )

      @session[@key] = valid_disco
      @manager.destroy_manager

      assert_nil(@session[@key])

      @session[@key] = invalid_disco
      @manager.destroy_manager

      assert_equal(@session[@key], invalid_disco)

      # Force destruction of manager, no matter which URLs it's for.
      @manager.destroy_manager(true)

      assert_nil(@session[@key])
    end

    def test_session_key
      assert(@manager.session_key.end_with?(
        @manager.instance_variable_get(:@session_key_suffix),
      ))
    end

    def test_store
      thing = "opaque"

      assert_nil(@session[@key])
      @manager.store(thing)

      assert_equal(@session[@key], thing)
    end

    def test_load
      thing = "opaque"
      @session[@key] = thing

      assert_equal(@manager.load, thing)
    end

    def test_destroy!
      thing = "opaque"
      @manager.store(thing)

      assert_equal(@manager.load, thing)
      @manager.destroy!

      assert_nil(@session[@key])
      assert_nil(@manager.load)
    end
  end
end
