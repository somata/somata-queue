somata = require 'somata'

class QueueClient extends somata.Client

    constructor: ->
        super
        @queue_subscriptions = {}

    queue: (priority, service, method, args..., cb) ->
        @remote 'queue', priority, service, method, args..., (err, queued) =>

            if queued.success

                if queued.new
                    somata.log.s '[queue] Newly queued ' + queued.job.key
                    @subscribeToJob queued.job, cb

                else
                    somata.log.i '[queue] Already queued: ' + queued.job.key

                    if !(queue_subscription = @queue_subscriptions[queued.job.key])
                        somata.log.w '[queue] No callback registered for ' + queued.job.key
                        @subscribeToJob queued.job, cb

            else
                somata.log.e '[queue] Couldn\'t queue'

    subscribeToJob: (job, cb) ->
        queue_subscription = @subscribe 'queue', 'completed:' + job.key, (err, response) =>
            somata.log.s '[queue] Was completed:', response
            @unsubscribe job.key
            cb err, response
        @queue_subscriptions[job.key] = queue_subscription

module.exports = QueueClient

