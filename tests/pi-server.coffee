somata = require 'somata'

new somata.Service 'pi',

    estimate: (points, cb) ->
        inside = 0
        i = points

        while (i--)
            if Math.pow(Math.random(), 2) + Math.pow(Math.random(), 2) <= 1
                inside++

        cb null, (inside/points)*4

