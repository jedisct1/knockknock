knockknock
==========

iOS and Goliath app to track the IP address of an iOS device and
poke firewall holes automagically.

This is just quick and super dirty code for my own use.

Server-side, this is a super simple server that accepts client HTTP
connections to "/knock". A super dumb token based on the current time
and a shared secret key is verified before calling a script that
temporarily whitelists the current client IP address.

Client-side, a HTTP query with the magic token is made when the
app starts, resumes, and when you switch to a new 3G cell tower. So
that you can just launch it and forget it. It has no impact on the battery.

I wrote that thing to use a custom APN proxy. Super ugly, but it does
the trick.

--

NOTE: Apparently, "Goliath" is the name of a tool to bypass the
iCloud activation lock. It is completely unrelated to this project.
