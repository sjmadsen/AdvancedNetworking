This demo shows off a simple publish/subscribe system that uses Faye
(http://faye.jcoglan.com) for the server component. There is both a Node.js
and Ruby server. I'm using the Ruby server here. To install and run it:

    $ bundle
    $ bundle exec thin -e production --port 9292 --rackup faye.ru start

The client is a simple iPhone app. It uses my fork of FayeObjC, which in
turn uses Square's SocketRocket for the underlying networking. You must
initialize both submodules before running the client.

    (from the top of the AdvancedNetworking working tree)
    $ git submodule update --init --recursive

Once both the server and client are running, the client will display any
message it receives (as an NSDictionary decoded from JSON). You can inject
messages into Faye using Curl:

    $ curl http://localhost:9292/faye -d 'message={"channel":"/channel", "data":"hello"}'

A more complex data structure:

    $ curl http://localhost:9292/faye -d 'message={"channel":"/channel", "data":{"key":"value"}}'
