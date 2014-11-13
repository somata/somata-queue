Queue = require 'somata-queue'
queue_service = new Queue 'queue', {}, {client_options: {connection_options: {timeout_ms: 10000}}}

