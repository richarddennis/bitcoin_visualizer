config      = require 'config'
_           = require 'lodash'
Moment      = require 'moment'

pageLimit = 10 # Should bump this up but don't want to wear out my welcome on the free API
#pageSizeLimit = 200
pollInterval = 1000 * 20

Blocks = () ->
  console.log 'block collection instantiated, fetching initial data'
  @curPage  = 1
  @pageSize = 200
  @getHistorical(null, @pollForLatest.bind @)

Blocks.prototype = new Array()

# Every element is parsed before it is added to the collection.
# The default implemenation should be a pass-through
Blocks.prototype.parse = (one) ->
  m = new Moment one.block_time
  one.date = m.format 'YYYY-MM-DD' # css classname safe date stamp (not time), so we can detect boundaries of day by locale
#  one.parsed = true
  one

Blocks.prototype.getLatest = ->
#  console.log 'getLatest'
  request = new XMLHttpRequest()
  request.open 'GET', "#{config.api}/v1/btc/block/latest?api_key=#{config.blocktrailKey}", true
  request.onerror = @gotErr.bind @
  request.onload  = (->
    if (request.status >= 200 && request.status < 400)
      @gotLatest.call @, JSON.parse request.responseText
    else
      gotErr request
  ).bind @
  request.send()

Blocks.prototype.gotLatest = (resp) ->
  console.log 'gotLatest', resp.hash
  wasInserted = @safeInsert @parse resp
  @onChangeCall() if wasInserted

Blocks.prototype.getHistorical = (page, callback) ->
  page = page || @curPage
  request = new XMLHttpRequest()
  request.open 'GET', "#{config.api}/v1/btc/all-blocks?page=#{page}&limit=#{@pageSize}&sort_dir=desc&api_key=#{config.blocktrailKey}", true
  request.onerror = @gotErr.bind @
  request.onload  = (->
    if (request.status >= 200 && request.status < 400)
      resp = JSON.parse request.responseText
      @gotHistorical.call @, resp
      callback.call @, resp if typeof callback is 'function'

    else
      gotErr request
  ).bind @
  request.send()

Blocks.prototype.gotHistorical = (resp) ->
#  console.log 'gotHistorical', resp
#  Array.prototype.push.apply @, resp.data # add the new data to this array
  for one in resp.data
    @push @parse one
  @onChangeCall()
  @curPage++
#  @pageSize *= 2 # Can't change the page size because then there will be overlaps. The API doesn't provide an offset option.
#  if @pageSize > pageSizeLimit then @pageSize = pageSizeLimit
  return if @curPage > pageLimit
  @getHistorical()

Blocks.prototype.gotErr = (req) ->  console.warn 'error response from server on collection/blocks', req
Blocks.prototype.conErr = ->        console.warn 'error setting up xhr request on collection/blocks', arguments

# Insert it, but not if that block already exists
# Expect an existing block to be at the front so optimize for testing that case
Blocks.prototype.safeInsert = (block) ->
  if @[0] and @[0].hash is block.hash
    return #console.debug "asked to re-insert a block that's already at the front, skipping it"
  else if _.find @, { hash: block.hash }
    return console.warn "asked to re-insert a block that isn't at the front, but is already in the data set"
  else
    console.info "blocks.safeInsert() Adding a new block to the front of the chain"
    return @unshift block


Blocks.prototype.pollForLatest = ->
  console.log 'pollForLatest'
  @getLatest()
  setInterval @getLatest.bind(@), pollInterval

#Blocks.prototype.stopPolling = ->

# Support adding a change handler
Blocks.prototype.onChange = (fn) ->
  @_handlers = @_handlers || {}
  @_handlers.onChange = @_handlers.onChange || []
  @_handlers.onChange.push fn

# Call all the handlers, if any
Blocks.prototype.onChangeCall = ->
  return unless @_handlers and @_handlers.onChange
  @_handlers.onChange.forEach (fn) ->
    fn.apply @, arguments

module.exports = Blocks
