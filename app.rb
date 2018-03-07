require 'sinatra'
require 'yaml'

require_relative 'lib/clients'
require_relative 'lib/authentication'

configure do
  set :server, :puma
end

class Pumatra < Sinatra::Base
  post '/api/1.0/client/:id/:command' do
    msg = "ID not an integer"
    return halt 500, msg unless params[:id].to_i

    id = params[:id].to_i

    msg = "No client exists with that ID"
    return halt 500, msg unless Kyuji::Clients.exists? id

    client = Kyuji::Clients[id]
    request.body.rewind

    msg = "Authentication failed"
    return halt 500, msg unless authenticated?(client['method'], client, request)

    command_path = client['command_dir'] + '/' + params[:command]

    msg = "Command not found"
    return halt 500, msg unless File.file? command_path

    File.open('log/commands.log', 'a') do |f|
      f.puts "\n"
      f.puts "[" + Time.now.to_s + "] Beginning command invocation..."
      f.puts "\n"
    end
    pid = spawn "#{command_path}", chdir: client['command_dir'],
                                   unsetenv_others: true,
                                   [:out] => ["log/commands.log", "a"]
    Process.detach pid

    msg = "Success"
    return 200, msg
  end

  not_found do
    redirect '/'
  end

  run! if app_file == $0
end
