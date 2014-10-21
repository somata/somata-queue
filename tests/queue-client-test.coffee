queue = require 'somata-queue'
somata = require 'somata'
util = require 'util'

showSet = (err, set) ->
    somata.log 'Set to', set

client1 = new queue.Client
client2 = new queue.Client
client1.queue 'high', 'lifx', 'set_rgb', 0, 0, 0, showSet
client2.queue 'high', 'lifx', 'set_rgb', 0, 0, 0, showSet
client1.queue 'high', 'lifx', 'set_rgb', 0, 0, 0, showSet

