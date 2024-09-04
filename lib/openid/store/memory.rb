require_relative "interface"

module OpenID
  module Store
    # An in-memory implementation of Store.  This class is mainly used
    # for testing, though it may be useful for long-running single
    # process apps.  Note that this store is NOT thread-safe.
    #
    # You should probably be looking at OpenID::Store::Filesystem
    class Memory < Interface
      def initialize
        @associations = Hash.new { |hash, key| hash[key] = {} }
        @nonces = {}
      end

      def store_association(server_url, assoc)
        assocs = @associations[server_url]
        @associations[server_url] = assocs.merge({assoc.handle => deepcopy(assoc)})
      end

      def get_association(server_url, handle = nil)
        assocs = @associations[server_url]
        if handle
          assocs[handle]
        else
          assocs.values.sort_by(&:issued)[-1]
        end
      end

      def remove_association(server_url, handle)
        assocs = @associations[server_url]
        return true if assocs.delete(handle)

        false
      end

      def use_nonce(server_url, timestamp, salt)
        return false if (timestamp - Time.now.to_i).abs > Nonce.skew

        nonce = [server_url, timestamp, salt].join("")
        return false if @nonces[nonce]

        @nonces[nonce] = timestamp
        true
      end

      def cleanup_associations
        count = 0
        @associations.each do |_server_url, assocs|
          assocs.each do |handle, assoc|
            if assoc.expires_in == 0
              assocs.delete(handle)
              count += 1
            end
          end
        end
        count
      end

      def cleanup_nonces
        count = 0
        now = Time.now.to_i
        @nonces.each do |nonce, timestamp|
          if (timestamp - now).abs > Nonce.skew
            @nonces.delete(nonce)
            count += 1
          end
        end
        count
      end

      protected

      def deepcopy(o)
        Marshal.load(Marshal.dump(o))
      end
    end
  end
end
