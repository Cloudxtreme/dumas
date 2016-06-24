log = require('./log').childLogger 'world'

class Exit
    constructor: (@full, @short, target) ->
        if target instanceof String or typeof target == 'string'
            @targetId = target
        else
            @targetRoom = target

    normalize: (world, room) ->
        if not @targetId? and not @targetRoom?
            world.errors++
            log.error "room #{room.id} exit #{@full} has no target id"
            return

        if @targetId? and not @targetRoom?
            @targetRoom = world.roomById[@targetId]
            if not @targetRoom?
                log.error "room #{room.id} exit #{@full} points to #{@targetId}, but this room doesn't exist"
                world.errors++

class Item
    constructor: (@id, @name, @short, @desc) ->

class Mob
    constructor: (@id, @name, @desc) ->

class Room
    constructor: (@id, @name, @desc) ->
        @exits = []
        @items = []
        @people = []

    normalize: (world) ->
        for exit in exits
            exit.normalize world

class World
    constructor: (@rooms) ->
        @errors = 0
    normalize: ->
        @roomById = {}
        for room in @rooms
            if @roomById[room.id]?
                @errors++
                log.error "room id #{room.id} duplicated"
            @roomById[room.id] = room
        for room in @rooms
            room.normalize world, this

newWorld = ->
    room1 = new Room('/path/byBrook', 'By the brook', """
    You're beside a brook. The path runs parallel to the brook. A few willows spread their branches across the water.
    """)
    room2 = new Room('/path/byWaterfall', 'By a waterfall', """
    You're on a narrow dirt path that leads from Guremcepa to Nawsia. Nearby, a stream falls down a waterfall, babbling like a herd of MPs.
    """)
    room1.exits.push new Exit("north", "n", room2)
    room2.exits.push new Exit("south", "s", '/path/byBrook')
    world = new World [room1, room2]
    world.normalize()
    return world

exports.Item = Item
exports.Mob = Mob
exports.Room = Room
exports.World = World
exports.newWorld = newWorld
