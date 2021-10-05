# frozen_string_literal: true

require 'puma/util'

module Puma
  class BindConfig

    # Builds a BindConfig object from a URI
    def self.parse(uri)
      uri = URI.parse(uri)
      new(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.port,
        path: uri.path,
        query: uri.query,
        params: Util.parse_query(uri.query)
      )
    end

    attr_reader :scheme, :host, :port, :path, :params

    def initialize(scheme: , host: , port: , path: nil, query: nil, params: {})
      @scheme = scheme
      @host = host
      @port = port
      @path = path
      @query = query
      @params = params
    end

    def query
      @query ||=
        begin
          # Don't add cert and key objects in the query params
          query_params = @params.slice(*@params.keys - ['cert_object', 'key_object'])

          # To properly handle file descriptors logic in binder, we need to
          # uniquelly identify the BindConfig as URI using cert_object details.
          if @params['cert_object']
            query_params['cert_serial'] = @params['cert_object'].serial.to_s
            query_params['cert_not_after'] = @params['cert_object'].not_after.utc.strftime('%Y-%m-%dT%H:%M:%S')
          end
          query_params.empty? ? nil : query_params.sort.map { |k, v| "#{k}=#{v}"}.join('&')
        end
    end

    def uri
      @uri ||=
        if scheme == 'unix'
          "unix://#{path}"
        else
          URI::Generic.build(scheme: scheme, host: host, port: port, path: path, query: query).to_s
        end
    end

    def ==(other)
      uri == other.uri
    end
  end
end
