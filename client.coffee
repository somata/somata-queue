somata = require 'somata'

class QueueClient extends somata.Client

    constructor: ->
        super
        @queue_service ||= 'queue'
        @queue_subscriptions = {}

    queue: (priority, service, method, args..., cb) ->
        onQueued = (err, queued) =>
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

        queue_msg = @makeQueueMsg priority, service, method, args
        @getServiceConnection @queue_service, (err, service_connection) ->
            if err
                somata.log.e err
            else
                service_connection.send queue_msg, onQueued

    subscribeToJob: (job, cb) ->
        subscription_id = @subscribe @queue_service, 'completed:' + job.key, (err, response) =>
            somata.log.s '[queue] Was completed:', job.key
            @unsubscribe subscription_id
            cb err, response
        @queue_subscriptions[job.key] = subscription_id

    makeQueueMsg: (priority, service, method, args) ->
        queue_msg = {
            kind: 'queue'
            priority
            service
            method
            args
        }

module.exports = QueueClient

