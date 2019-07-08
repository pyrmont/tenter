# frozen_string_literal: true

require "yaml"

module Tenter
  module Utils
    def self.config(site_dir)
      @config ||= {}
      @config[site_dir] ||=
        YAML.load_file(File.join(Tenter.settings[:doc_root],
                       site_dir,
                       Tenter.settings[:config_filename]))
    end

    def self.dir_exists?(site_dir)
      File.directory? File.join(Tenter.settings[:doc_root], site_dir)
    end

    def self.secret(site_dir)
      self.config(site_dir).fetch("secret", nil)
    end

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

    def self.append_to_log(log, statement)
      File.write(log, statement, mode: "a")
    end
  end
end
