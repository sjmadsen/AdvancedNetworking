$stdout.sync = true

require 'faye'

Faye::WebSocket.load_adapter('thin')
server = Faye::RackAdapter.new(:mount => '/faye', :timeout => 25)

run server
