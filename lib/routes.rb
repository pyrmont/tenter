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

  command_path = client['site_dir'] + '/' +
                 client['command_dir'] + '/' +
                 params[:command]

  msg = "Command not found"
  return halt 500, msg unless File.file? command_path

  # pid = spawn "#{command_path}"
  # Process.detach pid

  msg = "Success"
  return 200, msg
end