somata = require 'somata'

service = new somata.Service 'waiter',
    wait: (job_id, max, cb) ->
        t = Math.random() * max
        console.log 'waiting for', t
        is_done = false

        done = ->
            is_done = true
            cb null, "waited for #{t}"

        start = new Date().getTime()
        progress = ->
            if !is_done
                now = new Date().getTime()
                p = (now - start) / t
                console.log job_id, p
                service.publish 'progress:' + job_id, p
                setTimeout progress, 500

        setTimeout done, t
        setTimeout progress, 500

