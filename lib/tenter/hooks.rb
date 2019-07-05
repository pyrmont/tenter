# frozen_string_literal: true

require "sinatra/base"

module Tenter
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
