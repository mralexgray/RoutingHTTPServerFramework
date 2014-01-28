# What is RoutingHTTPServer?

A Framework distribution of [RoutingHTTPServer](https://github.com/mattstevens/RoutingHTTPServer)
for iOS and OS X.

# Motivation

The advantage of a framework distribution is that you only have to build it once.
A nested project or directly including the code (*shudder*) always builds everything
for a fresh build (e.g. after a clean).

A disadvantage is that you can't change the code of the Framework directly if you want
to. You also can't browse the source files to set breakpoints. But you *can* step into
the Framework functions. This makes debugging a little more difficult.
