require_relative "util"
require_relative "cryptutil"

module OpenID
  # Encapsulates a Diffie-Hellman key exchange.  This class is used
  # internally by both the consumer and server objects.
  #
  # Read more about Diffie-Hellman on wikipedia:
  # http://en.wikipedia.org/wiki/Diffie-Hellman

  class DiffieHellman
    # From the OpenID specification
    @@default_mod = 155_172_898_181_473_697_471_232_257_763_715_539_915_724_801_966_915_404_479_707_795_314_057_629_378_541_917_580_651_227_423_698_188_993_727_816_152_646_631_438_561_595_825_688_188_889_951_272_158_842_675_419_950_341_258_706_556_549_803_580_104_870_537_681_476_726_513_255_747_040_765_857_479_291_291_572_334_510_643_245_094_715_007_229_621_094_194_349_783_925_984_760_375_594_985_848_253_359_305_585_439_638_443
    @@default_gen = 2

    attr_reader :modulus, :generator, :public

    # A new DiffieHellman object, using the modulus and generator from
    # the OpenID specification
    def self.from_defaults
      DiffieHellman.new(@@default_mod, @@default_gen)
    end

    def initialize(modulus = nil, generator = nil, priv = nil)
      @modulus = modulus.nil? ? @@default_mod : modulus
      @generator = generator.nil? ? @@default_gen : generator
      set_private(priv.nil? ? OpenID::CryptUtil.rand(@modulus - 2) + 1 : priv)
    end

    def get_shared_secret(composite)
      DiffieHellman.powermod(composite, @private, @modulus)
    end

    def xor_secret(algorithm, composite, secret)
      dh_shared = get_shared_secret(composite)
      packed_dh_shared = OpenID::CryptUtil.num_to_binary(dh_shared)
      hashed_dh_shared = algorithm.call(packed_dh_shared)
      DiffieHellman.strxor(secret, hashed_dh_shared)
    end

    def using_default_values?
      @generator == @@default_gen && @modulus == @@default_mod
    end

    private

    def set_private(priv)
      @private = priv
      @public = DiffieHellman.powermod(@generator, @private, @modulus)
    end

    def self.strxor(s, t)
      if s.length != t.length
        raise ArgumentError, "strxor: lengths don't match. " +
          "Inputs were #{s.inspect} and #{t.inspect}"
      end

      if String.method_defined?(:bytes)
        s.bytes.to_a.zip(t.bytes.to_a).map { |sb, tb| sb ^ tb }.pack("C*")
      else
        indices = 0...(s.length)
        chrs = indices.collect { |i| (s[i] ^ t[i]).chr }
        chrs.join("")
      end
    end

    # This code is taken from this post:
    # <http://blade.nagaokaut.ac.jp/cgi-bin/scat.\rb/ruby/ruby-talk/19098>
    # by Eric Lee Green.
    def self.powermod(x, n, q)
      counter = 0
      n_p = n
      y_p = 1
      z_p = x
      while n_p != 0
        y_p = (y_p * z_p) % q if n_p[0] == 1
        n_p >>= 1
        z_p = (z_p * z_p) % q
        counter += 1
      end
      y_p
    end
  end
end
