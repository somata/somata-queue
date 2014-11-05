somata = require 'somata'
util = require 'util'
_ = require 'underscore'
crypto = require 'crypto'

DEFAULT_JOB_COMPLETED_PREFIX = 'completed:'
DEFAULT_JOB_LIMIT = 5
DEFAULT_JOB_INTERVAL = 1000

PRIORITY_NAMES = ['low', 'normal', 'high']
PRIORITIES = _.object PRIORITY_NAMES.map (n, i) -> [n, i]

# Filtering and sorting helpers
isRunning = (job) -> job.running
isRunnable = (job) -> job.scheduled <= new Date() && !isRunning job
prioritySort = (job) -> -1 * PRIORITIES[job.priority]
md5 = (s) -> crypto.createHash('md5').update(s).digest('hex')
makeKeyForJob = (job) -> md5 JSON.stringify(_.pick job, ['service', 'method', 'args'])
jobsDeduped = (jobs) -> _.uniq jobs, makeKeyForJob

class QueueService extends somata.Service

    constructor: ->
        super
        @client_options ||= {}
        _.extend @client_options, {parent: @}
        @client = new somata.Client @client_options

        @job_limit ||= DEFAULT_JOB_LIMIT
        @job_check_interval ||= DEFAULT_JOB_INTERVAL
        @job_completed_prefix ||= DEFAULT_JOB_COMPLETED_PREFIX
        @queued_jobs = {}

        @startRunningJobs()

    # Override handleMethod to interpret the given method name as a queue priority
    handleMethod: (client_id, message) ->
        if message.method == 'queue'
            job = @makeJob client_id, message
            @queue client_id, job
            @afterQueue job if @afterQueue?
        else
            super

    makeJob: (client_id, message) ->
        job =
            message_id: message.id
            client_id: client_id
            priority: message.args[0]
            service: message.args[1]
            method: message.args[2]
            args: message.args[3..]
            scheduled: new Date()
        job.key = makeKeyForJob job
        return job

    # Add a job to the queue
    queue: (client_id, job) ->
        if !@queued_jobs[job.key]?
            @queued_jobs[job.key] = job

    # Check jobs at an interval
    startRunningJobs: ->
        setInterval @runJobs.bind(@), @job_check_interval

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
        somata.log.d "[runJobs] Found #{ runnable_jobs.length } runnable jobs..." if runnable_jobs.length > 0
        runnable_jobs.map @runJob.bind(@)

    # Run a job and forward the result to the requesting client
    runJob: (job) ->
        somata.log.s '[runJob] Running ' + util.inspect job, colors: true
        job.running = true
        @client.remote job.service, job.method, job.args..., (err, response) =>
            if err? && err.timeout
                @runJob job
            else
                @sendQueueResponse job, response
                delete @queued_jobs[job.key]

    # Send a successful queue response
    sendQueueResponse: (job, response) ->
        @sendResponse job.client_id, job.message_id, response

    # TODO: Keep track of worker services and reschedule jobs if they fail

module.exports = QueueService

