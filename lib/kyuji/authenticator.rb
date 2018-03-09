module Kyuji
  module Authenticator
    def self.authenticated?(method, client, request)
      case method
      when 'github'
        use_github_method client, request
      else
        false
      end
    end

    def self.use_github_method(client, request)
      msg = "X-Hub-Signature header not set"
      raise msg unless request.env['HTTP_X_HUB_SIGNATURE']

      secret = client['secret']
      request_sig = request.env['HTTP_X_HUB_SIGNATURE']
      request_body = request.body.read
      computed_sig = 'sha1=' +
                     OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'),
                                             secret,
                                             request_body)
      Rack::Utils.secure_compare computed_sig, request_sig
    end
  end
end