module OpenID
  class Consumer
    # A set of discovered services, for tracking which providers have
    # been attempted for an OpenID identifier
    class DiscoveredServices
      attr_reader :current

      def initialize(starting_url, yadis_url, services)
        @starting_url = starting_url
        @yadis_url = yadis_url
        @services = services.dup
        @current = nil
      end

      def next
        @current = @services.shift
      end

      def for_url?(url)
        [@starting_url, @yadis_url].member?(url)
      end

      def started?
        !@current.nil?
      end

      def empty?
        @services.empty?
      end

      def to_session_value
        services = @services.map { |s| s.respond_to?(:to_session_value) ? s.to_session_value : s }
        current_val = @current.respond_to?(:to_session_value) ? @current.to_session_value : @current

        {
          'starting_url' => @starting_url,
          'yadis_url' => @yadis_url,
          'services' => services,
          'current' => current_val
        }
      end

      def ==(other)
        to_session_value == other.to_session_value
      end

      def self.from_session_value(value)
        return value unless value.is_a?(Hash)

        services = value['services'].map { |s| OpenID::OpenIDServiceEndpoint.from_session_value(s) }
        current = OpenID::OpenIDServiceEndpoint.from_session_value(value['current'])

        obj = new(value['starting_url'], value['yadis_url'], services)
        obj.instance_variable_set('@current', current)
        obj
      end
    end

    # Manages calling discovery and tracking which endpoints have
    # already been attempted.
    class DiscoveryManager
      def initialize(session, url, session_key_suffix = nil)
        @url = url

        @session = OpenID::Consumer::Session.new(session, DiscoveredServices)
        @session_key_suffix = session_key_suffix || 'auth'
      end

      def get_next_service
        manager = get_manager
        if !manager.nil? && manager.empty?
          destroy_manager
          manager = nil
        end

        if manager.nil?
          yadis_url, services = yield @url
          manager = create_manager(yadis_url, services)
        end

        if !manager.nil?
          service = manager.next
          store(manager)
        else
          service = nil
        end

        service
      end

      def cleanup(force = false)
        manager = get_manager(force)
        if !manager.nil?
          service = manager.current
          destroy_manager(force)
        else
          service = nil
        end
        service
      end

      protected

      def get_manager(force = false)
        manager = load
        return manager if force || manager.nil? || manager.for_url?(@url)

        nil
      end

      def create_manager(yadis_url, services)
        manager = get_manager
        raise StandardError, "There is already a manager for #{yadis_url}" unless manager.nil?
        return nil if services.empty?

        manager = DiscoveredServices.new(@url, yadis_url, services)
        store(manager)
        manager
      end

      def destroy_manager(force = false)
        return if get_manager(force).nil?

        destroy!
      end

      def session_key
        'OpenID::Consumer::DiscoveredServices::' + @session_key_suffix
      end

      def store(manager)
        @session[session_key] = manager
      end

      def load
        @session[session_key]
      end

      def destroy!
        @session[session_key] = nil
      end
    end
  end
end
