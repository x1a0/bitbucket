Http    = require 'http'
{spawn} = require 'child_process'
config  = require './config'

HOST = process.env.HOST ? '0.0.0.0'
PORT = process.env.PORT ? 8421

server = Http.createServer (req, res) ->
    # drop any requests dont have correct content-type
    if not req.headers['content-type']? or req.headers['content-type'] is not 'application/x-www-form-urlencoded'
        res.writeHead 200, {'Content-Type': 'text/plain'}
        return res.end 'Who are you?'

    req.setEncoding 'utf8'
    data = ''
    req.on 'data', (chunk) ->
        data += chunk

    req.on 'end', ->
        # data has 'payload=' prepended and is URL-encoded
        data = JSON.parse (decodeURIComponent data[8..]).replace /\++/g, ''
        console.log "Repo: #{data.repository.name}"
        if data.repository.name of config.repos
            cmd = 'git'
            args = ['pull']
            git = spawn cmd, args, {cwd: config.repos[data.repository.name].path}
            git.stderr.pipe process.stderr
            git.stdout.pipe process.stdout
            git.on 'exit', (status) ->
                console.log "[Git] Done." if status is 0

        res.writeHead 200, {'Content-Type': 'text/plain'}
        res.end()

server.listen PORT, HOST, ->
    console.log "server starting at http://#{HOST}:#{PORT}"
