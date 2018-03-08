require 'sinatra'
require 'yaml'

require_relative 'lib/kyuji'

class Pumatra < Sinatra::Base
  helpers Kyuji::Helpers

  post %r{/api/1.0/client/(?<id>[\d]+)/(?<command>[a-zA-Z][\S]*)} do
    set_client
    authenticate
    run_command

    msg = "Requested command initiated"
    return 200, msg
  end

  not_found do
    redirect '/'
  end

  run! if app_file == $0
end
