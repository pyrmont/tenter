# frozen_string_literal: true

require "yaml"

module Tenter

  # Utility functions for use by Tenter
  #
  # @since 0.1.1
  # @api private
  module Utils

    # Loads configuration data from a YAML file for a given directory
    #
    # @note The basename of the YAML file is specified in Tenter's configuration
    # settings.
    #
    # @param site_dir [String] the directory containing the YAML file
    #
    # @since 0.1.1
    # @api private
    def self.config(site_dir)
      @config ||= {}
      @config[site_dir] ||=
        YAML.load_file(File.join(Tenter.settings[:doc_root],
                       site_dir,
                       Tenter.settings[:config_filename]))
    end

    # Checks if the directory exists
    #
    # @note The directory provided must be given relative to the document root.
    #
    # @param site_dir [String] the directory to check
    #
    # @since 0.1.1
    # @api private
    def self.dir_exists?(site_dir)
      File.directory? File.join(Tenter.settings[:doc_root], site_dir)
    end

    # Returns the secret value for a particular directory
    #
    # @param site_dir [String} the directory
    #
    # @since 0.1.1
    # @api private
    def self.secret(site_dir)
      self.config(site_dir).fetch("secret", nil)
    end

    # Returns the details of the command to execute
    #
    # @note The directory provided must be given relative to the document root.
    #
    # @param command_name [String] the name of the file representing the
    #   command
    # @param site_dir [String} the directory containing the command
    #
    # @return [Hash] the details of the command to execute
    #
    # @since 0.1.1
    # @api private
    def self.command(command_name, site_dir)
      site_path = File.join(Tenter.settings[:doc_root], site_dir)
      command = {}
      command["dir"]  = File.join(site_path, Tenter.settings[:command_dir])
      command["path"] = File.join(command["dir"], command_name)
      command["log"]  = unless Tenter.settings[:log_file].nil?
                          File.join(site_path, Tenter.settings[:log_file])
                        else
                          "/dev/null"
                        end
      command["proc"] = Proc.new {
        ts = if Tenter.settings[:timestamp]
               %q{ | xargs -L 1 sh -c 'printf "[%s] %s\n" "$(date +%Y-%m-%d\ %H:%M:%S\ %z )" "$*" ' sh}
             else
               ""
             end
        spawn command["path"] + ts, { :chdir => command["dir"],
                                      [ :out, :err ] => [ command["log"], "a" ] }
      }

      return command
    end

    # Appends a statement to the log
    #
    # @param log [String] the file representing the log
    # @param statement [String] the statement to append to the log
    #
    # @since 0.1.0
    # @api private
    def self.append_to_log(log, statement)
      File.write(log, statement, mode: "a")
    end
  end
end
