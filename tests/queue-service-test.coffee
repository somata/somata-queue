Queue = require 'somata-queue'
meta_methods =
    get_queued_jobs: (cb) -> cb null, queue_service.queued_jobs
queue_service = new Queue 'queue', meta_methods, {client_options: {connection_options: {timeout_ms: 10000}}}

