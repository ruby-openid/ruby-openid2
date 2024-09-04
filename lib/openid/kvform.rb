module OpenID
  class KVFormError < Exception
  end

  module Util
    def self.seq_to_kv(seq, strict = false)
      # Represent a sequence of pairs of strings as newline-terminated
      # key:value pairs. The pairs are generated in the order given.
      #
      # @param seq: The pairs
      #
      # returns a string representation of the sequence
      err = lambda { |msg|
        msg = "seq_to_kv warning: #{msg}: #{seq.inspect}"
        raise KVFormError, msg if strict

        Util.log(msg)
      }

      lines = []
      seq.each do |k, v|
        unless k.is_a?(String)
          err.call("Converting key to string: #{k.inspect}")
          k = k.to_s
        end

        raise KVFormError, "Invalid input for seq_to_kv: key contains newline: #{k.inspect}" unless k.index("\n").nil?

        raise KVFormError, "Invalid input for seq_to_kv: key contains colon: #{k.inspect}" unless k.index(":").nil?

        err.call("Key has whitespace at beginning or end: #{k.inspect}") if k.strip != k

        unless v.is_a?(String)
          err.call("Converting value to string: #{v.inspect}")
          v = v.to_s
        end

        raise KVFormError, "Invalid input for seq_to_kv: value contains newline: #{v.inspect}" unless v.index("\n").nil?

        err.call("Value has whitespace at beginning or end: #{v.inspect}") if v.strip != v

        lines << k + ":" + v + "\n"
      end

      lines.join("")
    end

    def self.kv_to_seq(data, strict = false)
      # After one parse, seq_to_kv and kv_to_seq are inverses, with no
      # warnings:
      #
      # seq = kv_to_seq(s)
      # seq_to_kv(kv_to_seq(seq)) == seq
      err = lambda { |msg|
        msg = "kv_to_seq warning: #{msg}: #{data.inspect}"
        raise KVFormError, msg if strict

        Util.log(msg)
      }

      lines = data.split("\n")
      return [] if data.empty?

      if data[-1].chr != "\n"
        err.call("Does not end in a newline")
        # We don't expect the last element of lines to be an empty
        # string because split() doesn't behave that way.
      end

      pairs = []
      line_num = 0
      lines.each do |line|
        line_num += 1

        # Ignore blank lines
        next if line.strip == ""

        pair = line.split(":", 2)
        if pair.length == 2
          k, v = pair
          k_s = k.strip
          if k_s != k
            msg = "In line #{line_num}, ignoring leading or trailing whitespace in key #{k.inspect}"
            err.call(msg)
          end

          err.call("In line #{line_num}, got empty key") if k_s.empty?

          v_s = v.strip
          if v_s != v
            msg = "In line #{line_num}, ignoring leading or trailing whitespace in value #{v.inspect}"
            err.call(msg)
          end

          pairs << [k_s, v_s]
        else
          err.call("Line #{line_num} does not contain a colon")
        end
      end

      pairs
    end

    def self.dict_to_kv(d)
      seq_to_kv(d.entries.sort)
    end

    def self.kv_to_dict(s)
      seq = kv_to_seq(s)
      Hash[*seq.flatten]
    end
  end
end
