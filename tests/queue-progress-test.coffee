somata = require 'somata'
async = require 'async'

client = new somata.Client

bar_length = 80

bar = (p) ->
    n = bar_length * p
    ln = bar_length * (1-p)
    [0...n].map(-> '#').join('') + [0...ln].map(-> '_').join('')

sendRequest = (n, cb) ->
    showProgress = ({progress}) ->
        process.stdout.clearLine()
        process.stdout.cursorTo 0
        process.stdout.write "[#{sent_id}] / " + bar progress

    sent_id = client.remote 'queue', 'queue', {priority: 'low'}, 'waiter', 'wait', n*5000, (err, response) ->
        showProgress {progress: 1}
        console.log ' ' + response
        client.unsubscribe progress_subscription
        cb err, response

    progress_subscription = client.subscribe 'queue', 'progress:' + sent_id, showProgress

async.map [1..3], sendRequest, process.exit

