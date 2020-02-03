# frozen_string_literal: true

require "openssl"

module Tenter

  # Sinatra helpers for Tenter
  #
  # These helpers provide idiomatic methods for use in Sinatra routes. This
  # module is intended to be called by passing it to the `Sinatra::Base.helpers`
  # method.
  #
  # @since 0.1.1
  # @api private
  module Helpers

    # Authenticates the request
    #
    # @since 0.1.1
    # @api private
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

    # Executes the command
    #
    # @since 0.1.1
    # @api private
    def initiate
      command = Tenter::Utils.command params[:command_name], params[:site_dir]

      msg = "Command not found"
      halt 400, msg unless File.file? command["path"]

      ts = Tenter.settings[:timestamp] ? "[#{Time.now}] " : ""
      msg = ts + "Initiating: #{command["path"]}\n"
      Tenter::Utils.append_to_log command["log"], msg

      pid = if defined?(Bundler) && Bundler.respond_to?(:with_original_env)
              Bundler.with_original_env { command["proc"].call }
            else
              command["proc"].call
            end
      (ENV["APP_ENV"] != "test") ? Process.detach(pid) : Process.wait(pid)
    end

    # Generates the response's HTTP header status and body
    #
    # @param message [Symbol] the type of response
    # @since 0.1.1
    # @api private
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
