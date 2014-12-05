somata = require 'somata'
util = require 'util'
yargs = require 'yargs'

client = new somata.Client

s = yargs.argv.s || somata.helpers.randomString()
t = yargs.argv.t || 1000

setInterval ->
    client.call 'queue', 'queue', null, 'echo', 'echo', s, (err, response) ->
        somata.log '#2 --> ', response
, t

