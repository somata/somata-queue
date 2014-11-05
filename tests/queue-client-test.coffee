somata = require 'somata'
util = require 'util'
async = require 'async'

showResponse = (cb) -> (err, set) ->
    somata.log '--> ', set
    cb(err, set)

client1 = new somata.Client
client2 = new somata.Client
async.parallel
    one: (cb) -> client1.remote 'queue', 'queue', 'low', 'echo', 'echo', 'Testing1', showResponse cb
    two: (cb) -> client2.remote 'queue', 'queue', 'high', 'echo', 'echo', 'Testing2', showResponse cb
    three: (cb) -> client1.remote 'queue', 'queue', 'high', 'echo', 'echo', 'Testing3', showResponse cb
, process.exit

