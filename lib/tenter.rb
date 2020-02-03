# frozen_string_literal: true

require "tenter/helpers"
require "tenter/hooks"
require "tenter/utils"
require "tenter/version"

# A web app that provides webhooks for GitHub
#
# Tenter is a Sinatra-based web application that provides webhooks for use by
# GitHub. It is intended to be used as a gem in a Rack app.
#
# At its simplest, a user could write a `config.ru` file consisting of:
#
#     require "tenter"
#
#     run Tenter::Hooks
#
# Tenter comes with a series of sane defaults. A version of Tenter that uses
# these will expose endpoints in the form `/run/<action>/in/<dirname>/`. HTTP
# POST requests sent to such an endpoint will, if authenticated, result in
# Tenter executing the file on your the server's local file system at
# `/<doc_root>/<dirname>/commands/<action>`.
#
# As astute readers will have observed, this is a potentially massive security
# vulnerability. I am nevertheless able to sleep at night because Tenter
# will only execute a file matching the action in a given directory if:
#
# 1. the POST request includes an `HTTP_X_HUB_SIGNATURE` header; and
# 2. the value of this header matches the result of cryptographically
#    signing the body of the HTTP request with a key defined by the user.
#
# By default, the key defined by the user is located in
# `/<doc_root>/<dirname>/hooks.yaml`.
#
# A user can override the default settings for their instance of Tenter by
# defining one or more of the following:
#
# - `:doc_root` (default: `"/var/www"`): The root directory in which each
#   exposed directory will be located. It's recommended to specify this as an
#   absolute path.
#
# - `:config_filename` (default: `"hooks.yaml"`): The filename of the
#   configuration file in each exposed directory.
#
# - `:command_dir` (default: `"commands"`): The name of the subdirectory
#   in which the files to execute are located.
#
# - `:log_file` (default `"log/commands.log"`): The path to the log file in each
#   exposed directory where output from your commands will be logged. You can
#   set this to `nil`to disable logging.
#
# The easiest way to do that is in the `config.ru` file:
#
#     require "tenter"
#
#     Tenter.settings = { log_file: nil } # disable logging
#
#     run Tenter::Hooks
#
# @since 0.1.1
# @see https://github.com/pyrmont/tenter
module Tenter

  # Returns the default settings
  #
  # @return [Hash] the default settings
  #
  # @since 0.1.1
  def self.defaults
    { doc_root: "/var/www/",
      config_filename: "hooks.yaml",
      command_dir: "commands",
      log_file: "log/commands.log",
      timestamp: true }
  end

  # Resets Tenter's settings to their defaults
  #
  # @since 0.1.1
  def self.reset
    @settings = self.defaults
  end

  # Updates the provided settings
  #
  # @param opts [Hash] the keys and values to update
  #
  # @since 0.1.1
  def self.settings=(opts = {})
    @settings = self.settings.merge opts
  end

  # Returns the settings for this instance
  #
  # @return [Hash] the settings for this instance
  #
  # @since 0.1.1
  def self.settings
    @settings ||= self.defaults
  end
end
