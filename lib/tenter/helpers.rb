# frozen_string_literal: true

require "openssl"

module Tenter
  module Helpers
    def authenticate
      msg = "X-Hub-Signature header not set"
      halt 400, msg unless request.env['HTTP_X_HUB_SIGNATURE']

      msg = "X-Hub-Signature header did not match"
      halt 403, msg unless Tenter::Utils.dir_exists? params[:site_dir]
      
      secret = Tenter::Utils.secret params[:site_dir]

      request_sig = request.env['HTTP_X_HUB_SIGNATURE']
      request_body = request.body.read
      computed_sig = 'sha1=' +
                     OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'),
                                             secret,
                                             request_body)
      
      msg = "X-Hub-Signature header did not match"
      halt 403, msg unless Rack::Utils.secure_compare computed_sig, request_sig
    end

    def initiate
      command = Tenter::Utils.command params[:command_name], params[:site_dir]

      msg = "Command not found"
      halt 400, msg unless File.file? command["path"]

      msg = "[#{Time.now}] Initiating: #{command["path"]}\n"
      Tenter::Utils.append_to_log command["log"], msg

      pid = command["proc"].call
      (ENV["APP_ENV"] != "test") ? Process.detach(pid) : Process.wait(pid)
    end

    def notify(message)
      case message
      when :initiated
        return 200, "Command initiated"
      when :missing
        halt 404, "Page not found"
      end
    end
  end
end
