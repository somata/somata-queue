console.log 'Welcome to queue-ui.'

Loader = React.createClass
    getInitialState: ->
        loading: true

    componentWillMount: ->
        JobsDispatcher.loading.onValue (loading) =>
            @setState {loading}

    render: ->
        if @state.loading then `<em className='loading'>Loading...</em>` else null

JobsSummary = React.createClass
    getInitialState: ->
        selected: null
        jobs: []

    componentWillMount: ->
        JobsDispatcher.selections.onValue (selected) =>
            @setState {selected}
        JobsDispatcher.updates.onValue =>
            @setState jobs: JobsStore.jobs

    render: ->
        jobs = @state.jobs
        client_ids = _.countBy jobs, 'client_id'
        counts = _.pairs(client_ids).map @renderClientCount

        `(
            <div className="summary">
                <h2>{jobs.length} jobs</h2>
                {counts}
            </div>
        )`

    renderClientCount: ([client, count]) ->
        selectClient = =>
            if @state.selected == client
                selected = null
            else
                selected = client
            JobsDispatcher.selections.push selected
        clientClass = 'client ' + if @state.selected == client then 'selected' else ''

        `(
            <p>
                <strong
                    className={clientClass}
                    onClick={selectClient}
                >{client}</strong>: {count}
            </p>
        )`

Jobs = React.createClass
    getInitialState: ->
        selected: null
        jobs: []

    componentWillMount: ->
        JobsDispatcher.selections.onValue (selected) =>
            @setState selected: selected
        JobsDispatcher.updates.onValue =>
            @setState jobs: JobsStore.jobs

    render: ->
        jobs = @state.jobs
        client_ids = _.countBy jobs, 'client_id'

        if selected = @state.selected
            jobs = jobs.filter (j) -> j.client_id == selected
        job_views = jobs[..100].map @renderJob

        `<div>{job_views}</div>`

    renderJob: (job) ->
        `<Job job={job} key={job.key} />`

Job = React.createClass
    render: ->
        job = @props.job
        method_summary = "#{job.service}.#{job.method}(#{job.args.join(', ')})"
        `(
            <div className="job">
                <span className="method">{method_summary}</span>
                <span className="client_id">{job.client_id}</span>
            </div>
        )`

JobsStore =
    jobs: []

JobsDispatcher =
    loading: new Bacon.Bus()
    updates: new Bacon.Bus()
    selections: new Bacon.Bus()

React.render `<Loader />`, $('#loader')[0]
React.render `<JobsSummary />`, $('#jobs-summary')[0]
React.render `<Jobs />`, $('#jobs')[0]

updateJobs = ->
    JobsDispatcher.loading.push 1
    remote 'queue', 'get_queued_jobs', (err, queued) ->
        console.log '[get_queued_jobs]', queued
        JobsStore.jobs = _.values queued
        JobsDispatcher.loading.push 0
        JobsDispatcher.updates.push 'updated'

setInterval updateJobs, 1000
updateJobs()

