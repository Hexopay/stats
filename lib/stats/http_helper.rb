require 'net/http'
require 'net/https'

module Stats
  module HttpHelper
    def get(url, headers = {})
      request_type = Net::HTTP::Get
      make_request(request_type, url, nil, headers)
    end

    def post(url, body, headers = {})

      request_type = Net::HTTP::Post
      make_request(request_type, url, body, headers)
    end

    def put(url, body, headers = {})
      request_type = Net::HTTP::Post
      make_request(request_type, url, body, headers)
    end

    private

    def make_request(request_type, url, body, headers)
      uri = URI(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      # http = Net::HTTP.new(uri.host, uri.port, 'localhost', 8080)
      # if uri.scheme == "https"  # enable SSL/TLS
      #   http.use_ssl = true
      #   # Only needed for ruby 1.8.6
      #   # http.enable_post_connection_check = true
      #   #http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      #   http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      #   #  http.ca_file = File.join(File.dirname(__FILE__), "owasp_zap_root_ca.cer")
      #   http.ca_file = '/home/rob/tools/ZAP_2.9.0_Linux/ZAP_2.9.0/owasp_zap_root_ca.cer'
      # end

      req = request_type.new(uri.request_uri, headers)

      req.body = body unless body.nil?

      res = http.request(req)

      {
        status: res.code.to_i,
        body: res.body
      }
    end
  end
end
