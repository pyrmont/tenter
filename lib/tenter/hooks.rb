# frozen_string_literal: true

require "sinatra/base"

module Tenter

  # The Sinatra application
  #
  # This sets out the routes for the Sinatra application.
  #
  # @since 0.1.1
  # @api private
  class Hooks < Sinatra::Base
    helpers Tenter::Helpers

    post %r{/run/(?<command_name>\w[^\\\/\s]*)/in/(?<site_dir>\w[^\\\/\s]*)/?} do
      authenticate
      initiate
      notify :initiated
    end

    not_found do
      notify :missing
    end
  end
end
