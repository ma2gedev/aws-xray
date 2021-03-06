require 'uri'
require 'rack'

module Aws
  module Xray
    attrs = [:method, :url, :user_agent, :client_ip, :x_forwarded_for, :traced]
    class Request < Struct.new(*attrs)
      class << self
        def build(method:, url:, user_agent: nil, client_ip: nil, x_forwarded_for: nil, traced: nil)
          new(encode(method), drop_params(encode(url)), encode(user_agent), encode(client_ip), x_forwarded_for, traced)
        end

        def build_from_rack_env(env)
          req = ::Rack::Request.new(env)
          build(
            method: req.request_method,
            url: req.url,
            user_agent: req.user_agent,
            client_ip: req.ip,
            x_forwarded_for: !!env['HTTP_X_FORWARDED_FOR'],
            traced: nil,
          )
        end

        def build_from_faraday_env(env, traced: false)
          build(
            method: env.method.to_s.upcase,
            url: env.url.to_s,
            user_agent: env.request_headers['User-Agent'],
            client_ip: nil,
            x_forwarded_for: nil,
            traced: traced,
          )
        end

        private

        # Ensure all strings have same encoding to JSONify them.
        # If the given string has illegal bytes or a undefined byte sequence,
        # replace them with a default character.
        def encode(str)
          if str.nil?
            nil
          else
            str.to_s.encode(__ENCODING__, invalid: :replace, undef: :replace)
          end
        end

        def drop_params(str)
          uri = URI.parse(str)
          uri.query = nil
          uri.fragment = nil
          uri.to_s
        rescue URI::InvalidURIError
          str
        end
      end

      def to_h
        super.delete_if {|_, v| v.nil? }
      end
    end
  end
end
