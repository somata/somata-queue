queue = require 'somata-queue'
queue_service = new queue.Service 'queue', {}, {job_limit: 1}

