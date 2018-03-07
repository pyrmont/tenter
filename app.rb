require 'sinatra'
require 'yaml'

require_relative 'lib/kyuji'

class Pumatra < Sinatra::Base
  helpers Kyuji::Helpers

  post '/api/1.0/client/:id/:command' do
    set_client
    authenticate
    run_command

    msg = "Success"
    return 200, msg
  end

  not_found do
    redirect '/'
  end

  run! if app_file == $0
end
