
path = require 'path'
express = require 'express'
http = require 'http'
ChatService = require 'chat-service'

app = express()
router = express.Router()
views = path.join __dirname, '/views'

if app.get('env') == 'development'
  app.locals.pretty = true
  resources = path.join __dirname, '/public-dev'
  livereload = (require 'livereload').createServer(exts : ['jade'])
  livereload.watch [resources, views]
else
  resources = path.join __dirname, '/public'

app.set 'views', views
app.set 'view engine', 'jade'

app.use '/', router
app.use express.static resources
router.get '/', (req, res) -> res.render 'index'

server = require('http').Server app


onConnect = (service, id) ->
  socket = service.nsp.connected[id]
  unless socket then throw new Error()
  unless socket.handshake.query?.user
    throw new Error 'No login data.'
  Promise.resolve socket.handshake.query.user

if process.env.CHAT_REDIS_CONNECT
  state = 'redis'
  stateOptions =  { redisOptions : process.env.CHAT_REDIS_CONNECT }
  adapter = 'redis'
  adapterOptions = process.env.CHAT_REDIS_CONNECT
else
  state = 'memory'
  adapter = 'memory'

port = process.env.CHAT_PORT || 8000
app.locals.CHAT_PORT = port

options =  { enableUserlistUpdates : true, port
  , state, stateOptions, adapter, adapterOptions }

chat = new ChatService options, { onConnect }

process.on 'SIGINT', ->
  chat.close().finally ->
    console.log 'chat-service stopped'
    process.exit()
  .catch (e) -> console.error e

chat.addRoom 'default', { adminlist: ['admin'], owner : 'admin' }
.catch (e) -> console.error e


module.exports = app
