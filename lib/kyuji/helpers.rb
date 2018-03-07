module Kyuji

  # A set of helper methods.
  #
  # @since 1.0.0
  # @api private
  module Helpers

    # Authenticate the current request.
    #
    # @since 1.0.0
    # @api private
    def authenticate()
      msg = "Authentication failed"
      halt 403, msg unless Kyuji.authenticated?(@client['method'],
                                                       @client,
                                                       request)
    end

    # Run the specified command.
    #
    # @since 1.0.0
    # @api private
    def run_command()
      command_path = @client['command_dir'] + '/' + params[:command]
      valid_command? command_path

      start_log

      command = ->() {
        pid = spawn "#{command_path}", chdir: @client['command_dir'],
                                       [:out] => ["log/commands.log", "a"]
        Process.detach pid
      }

      if defined?(Bundler) && Bundler.respond_to?(:with_clean_env)
        Bundler.with_clean_env { command.call }
      else
        command.call
      end
    end

    # Set the +@client+ instance variable.
    #
    # @since 1.0.0
    # @api private
    def set_client()
      valid_id?
      @client = Kyuji::Clients[params[:id].to_i]
    end

    # Start the log.
    #
    # @since 1.0.0
    # @api private
    def start_log()
      File.open('log/commands.log', 'a') do |f|
        f.puts "\n"
        f.puts "[" + Time.now.to_s + "] Beginning command invocation..."
        f.puts "\n"
      end
    end

    # Check the client ID.
    #
    # @since 1.0.0
    # @api private
    def valid_id?()
      msg = "ID not an integer"
      halt 400, msg unless params[:id].to_i
      msg = "No client exists with that ID"
      halt 400, msg unless Kyuji::Clients.exists? params[:id].to_i
    end

    # Check the requested command.
    #
    # @since 1.0.0
    # @api private
    def valid_command?(command_path)
      msg = "Command not found"
      halt 400, msg unless File.file? command_path
    end
  end
end