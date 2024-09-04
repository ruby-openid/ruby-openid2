require_relative "test_helper"
require_relative "testutil"
require "openid/kvpost"
require "openid/kvform"
require "openid/message"

module OpenID
  class KVPostTestCase < Minitest::Test
    include FetcherMixin

    def mk_resp(status, resp_hash)
      MockResponse.new(status, Util.dict_to_kv(resp_hash))
    end

    def test_msg_from_http_resp_success
      resp = mk_resp(200, {"mode" => "seitan"})
      msg = Message.from_http_response(resp, "http://invalid/")

      assert_equal({"openid.mode" => "seitan"}, msg.to_post_args)
    end

    def test_400
      args = {
        "error" => "I ate too much cheese",
        "error_code" => "sadness",
      }
      resp = mk_resp(400, args)
      begin
        val = Message.from_http_response(resp, "http://invalid/")
      rescue ServerError => e
        assert_equal("I ate too much cheese", e.error_text)
        assert_equal("sadness", e.error_code)
        assert_equal(e.message.to_args, args)
      else
        raise("Expected exception. Got: #{val}")
      end
    end

    def test_500
      args = {
        "error" => "I ate too much cheese",
        "error_code" => "sadness",
      }
      resp = mk_resp(500, args)
      assert_raises(HTTPStatusError) do
        Message.from_http_response(resp, "http://invalid")
      end
    end

    def make_kv_post_with_response(status, args)
      resp = mk_resp(status, args)
      mock_fetcher = Class.new do
        define_method(:fetch) do |_url, _body, _xxx, _yyy|
          resp
        end
      end

      with_fetcher(mock_fetcher.new) do
        OpenID.make_kv_post(Message.from_openid_args(args), "http://invalid/")
      end
    end

    def test_make_kv_post
      assert_raises(HTTPStatusError) do
        make_kv_post_with_response(500, {})
      end
    end
  end
end
