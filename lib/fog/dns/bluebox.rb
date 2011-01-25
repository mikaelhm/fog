module Fog
  module Bluebox
    class DNS < Fog::Service
      requires :bluebox_api_key, :bluebox_customer_id
      recognizes :bluebox_host, :bluebox_port, :bluebox_scheme, :persistent
      recognizes :provider # remove post deprecation

      model_path 'fog/dns/models/bluebox'
      model       :record
      collection  :records
      model       :zone
      collection  :zones

      request_path 'fog/dns/requests/bluebox'
      request :create_record
      request :delete_record
      request :get_record
      request :get_records
      request :get_zone
      request :get_zones

      class Mock
        def self.data
          @data ||= Hash.new do |hash, key|
            hash[key] = {}
          end
        end

        def self.reset_data(keys=data.keys)
          for key in [*keys]
            data.delete(key)
          end
        end

        def initialize(options={})
          unless options.delete(:provider)
            location = caller.first
            warning = "[yellow][WARN] Fog::Bluebox::DNS.new is deprecated, use Fog::DNS.new(:provider => 'Bluebox') instead[/]"
            warning << " [light_black](" << location << ")[/] "
            Formatador.display_line(warning)
          end

          @bluebox_customer_id = options[:bluebox_customer_id]
          @bluebox_api_key = options[:bluebox_api_key]
          @data = self.class.data[@bluebox_customer_id]
          @data = self.class.data[@bluebox_api_key]
        end
      end

      class Real
        def initialize(options ={})
          unless options.delete(:provider)
            location = caller.first
            warning = "[yellow][WARN] Fog::Bluebox::DNS.new is deprecated, use Fog::DNS.new(:provider => 'Bluebox') instead[/]"
            warning << " [light_black](" << location << ")[/] "
            Formatador.display_line(warning)
          end

          @bluebox_customer_id = options[:bluebox_customer_id]
          @bluebox_api_key = options[:bluebox_api_key]

          @host   = options[:host]    || "boxpanel.bluebox.net"
          @port   = options[:port]    || 443
          @scheme = options[:scheme]  || 'https'
          @connection = Fog::Connection.new("#{@scheme}://#{@host}:#{@port}", options[:persistent])
        end

        def reload
          @connection.reset
        end

        def request(params)
          params[:headers] ||= {}

          params[:headers]['Authorization'] = "Basic #{auth_header}"

          case params[:method]
          when 'DELETE', 'GET', 'HEAD'
            params[:headers]['Accept'] = 'application/xml'
          when 'POST', 'PUT'
            params[:headers]['Content-Type'] = 'application/xml'
          end

          begin
            response = @connection.request(params.merge!({:host => @host}))
          rescue Excon::Errors::HTTPStatusError => error
            raise case error
            when Excon::Errors::NotFound
              Fog::Bluebox::DNS::NotFound.slurp(error)
            else
              error
            end
          end

          response
        end

        protected

        def auth_header
          @auth_header ||= Base64.encode64("#{@bluebox_customer_id}:#{@bluebox_api_key}").gsub("\n",'')
        end

      end
    end
  end
end