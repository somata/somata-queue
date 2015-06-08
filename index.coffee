somata = require 'somata'
util = require 'util'
_ = require 'underscore'

DEFAULT_JOB_COMPLETED_PREFIX = 'completed:'
DEFAULT_JOB_LIMIT = parseInt(process.env.SOMATA_JOB_LIMIT) || 5
DEFAULT_JOB_INTERVAL = parseInt(process.env.SOMATA_JOB_INTERVAL) || 1000

PRIORITY_NAMES = ['low', 'normal', 'high']
PRIORITIES = _.object PRIORITY_NAMES.map (n, i) -> [n, i]

# Filtering and sorting helpers
isRunning = (job) -> job.running
isRunnable = (job) -> job.scheduled <= new Date().getTime() && !isRunning job
prioritySort = (job) -> -1 * PRIORITIES[job.priority]
jobSummary = (job) -> _.pick job, ['client_id', 'service', 'method', 'args']
makeKeyForJob = (job) -> somata.helpers.hashobj jobSummary job
jobsDeduped = (jobs) -> _.uniq jobs, makeKeyForJob

# Helpers for extending objects
ex = (o, a...) -> _.extend {}, o, a...
dx = (o, a...) -> _.defaults (ex o), a...

class QueueService extends somata.Service

    # TODO:
    # * Persist jobs in Redis or Mongo
    # * Keep track of worker services and reschedule jobs if they fail
    # * Send jobs of the same key to newly subscribed hosts without re-queueing

    constructor: ->
        super
        @client_options ||= {}
        _.extend @client_options, {parent: @}
        @client = new somata.Client @client_options

        @job_limit ||= DEFAULT_JOB_LIMIT
        @job_interval ||= DEFAULT_JOB_INTERVAL
        @job_completed_prefix ||= DEFAULT_JOB_COMPLETED_PREFIX
        @queued_jobs = {}

        @startRunningJobs()

    # Override handleMethod to interpret the given method name as a queue priority
    handleMethod: (client_id, message) ->
        if message.method == 'queue'
            @handleQueue client_id, message
        else
            super

    handleQueue: (client_id, message) ->
        job = @makeJob client_id, message
        @queue client_id, job
        @afterQueue job if @afterQueue?

    # queue [{options}] [service] [method] [args...]
    makeJob: (client_id, message) ->
        options = message.args[0] || {}
        job = dx options,
            priority: 'normal'
            message_id: message.id
            client_id: client_id
            service: message.args[1]
            method: message.args[2]
            args: message.args[3..]
            scheduled: new Date().getTime()
        job.key = makeKeyForJob job
        #somata.log.i '[makeJob]', job
        return job

    # Add a job to the queue
    queue: (client_id, job) ->
        if !@queued_jobs[job.key]?
            @queued_jobs[job.key] = job

    # Check jobs at an interval
    startRunningJobs: ->
        setInterval @runJobs.bind(@), @job_interval

    # Check for runnable jobs
    runJobs: ->
        all_jobs = _.values(@queued_jobs)
        # Get jobs that aren't running sorted by priority
        runnable_jobs = all_jobs.filter(isRunnable)
        runnable_jobs = _.sortBy runnable_jobs, prioritySort
        # Take only enough to reach our job limit
        n_running = all_jobs.filter(isRunning).length
        runnable_jobs = _.first runnable_jobs, @job_limit - n_running
        # Run them
        #somata.log.d "[runJobs] Found #{ runnable_jobs.length } runnable jobs from #{ all_jobs.length }..." if runnable_jobs.length > 0
        run_outgoing_ids = runnable_jobs.map @runJob.bind(@)

    # Run a job and forward the result to the requesting client
    runJob: (job) ->
        #somata.log.s '[runJob] Running ' + util.inspect job, colors: true
        job.running = true
        job.outgoing_id = @client.call job.service, job.method, job.args..., (err, response) =>

            # Re-run it if timed out
            # TODO: Add it to the end of the queue
            if err? && err.timeout
                @runJob job

            else
                @sendQueueResponse job, response
                delete @queued_jobs[job.key]

    # Send a successful queue response
    sendQueueResponse: (job, response) ->
        @sendResponse job.client_id, job.message_id, response

module.exports = QueueService

