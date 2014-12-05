somata = require 'somata'
util = require 'util'
async = require 'async'
yargs = require 'yargs'

showResponse = (cb) -> (err, set) ->
    somata.log '--> ', set
    cb(err, set) if cb?

client = new somata.Client

n = 0
rn = 0
max = yargs.argv.max || 100
run_n = (err, cb) ->
    client.remote 'queue', 'queue', {priority: 'low'}, 'echo', 'echo', 'Testing ' + n++, showResponse (err, set) ->
        rn++
setInterval ->
    if n < max
        run_n()
    if rn == n
        process.exit()
, 10

