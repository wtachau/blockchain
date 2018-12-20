require "sinatra"
require "sinatra-websocket"

require "Haml"

STATE = {}

set :server, "thin"
set :sockets, []
configure do
  set :protection, except: [:frame_options]
end

def update_socket_data
  settings.sockets.each do |s|
    s.send(
      STATE.to_json
    )
  end
end

post "/state" do

  params = JSON.parse(request.body.read)

  STATE[params["from"]] = params["state"]

  update_socket_data
  puts STATE

end

get "/" do
  if !request.websocket?
    haml :index
  else
    request.websocket do |ws|
      ws.onopen do
        settings.sockets << ws
        update_socket_data
      end
      ws.onclose do
        settings.sockets.delete(ws)
      end
    end
  end
end
