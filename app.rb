require 'sinatra'
require 'yaml'

require_relative 'lib/kyuji'

class Pumatra < Sinatra::Base
  api_ver = Kyuji::API_VERSION

  helpers Kyuji::Helpers

  post %r{/api/#{api_ver}/client/(?<id>[\d]+)/(?<command>[a-zA-Z][\S]*)} do
    set_client
    authenticate
    run_command

    msg = "Requested command initiated"
    return 200, msg
  end

  post %r{/api/#{api_ver}/.+} do
    msg = "Unsupported API request"
    halt 400, msg
  end

  post %r{/api/(?<id>[\d]+\.[\d]+)/.+} do
    msg = "Unsupported API version"
    halt 400, msg
  end

  post %r{/api/.*} do
    msg = "Malformed API request"
    halt 400, msg
  end

  not_found do
    redirect '/'
  end

  run! if app_file == $0
end
