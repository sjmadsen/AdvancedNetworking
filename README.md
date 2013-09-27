# Overview

This is the demo code for my Advanced Cocoa Networking talk.

If you happen to be looking for code from a particular conference, HEAD may
not match up with you want. Check the tags for a different point in the
history.

The slides are available at [Speaker Deck](https://speakerdeck.com/u/sjmadsen/p/advanced-cocoa-networking).

# PubSub

This demo shows how to run a Faye Ruby server and subscribe to messages sent
to a channel from within an iOS app.

# SimpleEcho

This demo is a simple TCP echo client and server in a single Mac app. The
server runs on port 5000.

# BonjourEcho

BonjourEcho modifies SimpleEcho to bind to an ephemeral port and advertise
the _lys-echo._tcp service using Bonjour. If the client finds more than one
system advertising the service, it will pick one at random. A more serious
implementation would present a UI with the available services and allow
the user to pick one.

# GameKitChat

This demonstrates a very simple use of GameKit P2P networking.

# PeerThroughput

This uses the Multipeer Connectivity framework in iOS 7 to measure the ping
and throughput between peers.
