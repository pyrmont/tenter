# frozen_string_literal: true

require "tenter/helpers"
require "tenter/hooks"
require "tenter/utils"
require "tenter/version"

module Tenter
  def self.defaults
    { doc_root: "/var/www/",
      config_filename: "hooks.yaml",
      command_dir: "commands",
      log_file: "log/commands.log" }
  end

  def self.reset
    @settings = self.defaults
  end

  def self.settings=(opts = {})
    @settings = self.settings.merge opts
  end

  def self.settings
    @settings ||= self.defaults 
  end
end
