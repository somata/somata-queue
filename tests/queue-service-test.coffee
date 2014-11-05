Queue = require 'somata-queue'
queue_service = new Queue 'queue', {}, {job_limit: 1}

