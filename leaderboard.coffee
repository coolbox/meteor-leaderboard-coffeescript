# Set up a collection to contain player information. On the server,
# it is backed by a MongoDB collection named "players".
Players = new Meteor.Collection("players")

resetTable = () ->
  Players.remove({})
  if Players.find().count() == 0
    names = ["Ada Lovelace", 
             "Grace Hopper", 
             "Marie Curie", 
             "Carl Friedrich Gauss", 
             "Nikola Tesla", 
             "Claude Shannon"]
    i = 0

    for name in names
      Players.insert
        name: name
        score: score()

resetScores = () ->
  Players.find().forEach (player) ->
    Players.update player._id, 
      $set:
        score: score()

score = () ->
  return Math.floor(Random.fraction() * 10) * 5

addScientist = (name) ->
  Players.insert
    name: name
    score: 0

removeScientist = () ->
  scientist = Players.findOne(Session.get "selected_player")
  Players.remove scientist._id

Validation =
  clear: ->
    return Session.set("error", undefined)
  
  set_error: (message) ->
    return Session.set("error", message)

  valid_name: (name) ->
    this.clear()
    if name.length == 0
      this.set_error "Name can't be blank"
      return false
    else if this.player_exists name
      this.set_error "Player already exists"
      return false
    else
      return true
    
  player_exists: (name) ->
    return Players.findOne
      name: name

if Meteor.isClient
  Meteor.startup ->
    Session.set "sort_order",
      score: -1
      name: 1

  Template.leaderboard.players = ->
    Players.find {},
      sort: Session.get("sort_order")

  Template.leaderboard.selected_name = ->
    player = Players.findOne(Session.get("selected_player"))
    player and player.name

  Template.player.selected = ->
    (if Session.equals("selected_player", @_id) then "selected" else "")

  Template.leaderboard.error = ->
    return Session.get "error"

  Template.leaderboard.events =
    "click input.inc": ->
      Players.update Session.get("selected_player"),
        $inc:
          score: 5

    "click input.sort": ->
      sortOrder = Session.get("sort_order")
      if Object.keys(sortOrder)[0] is "score" # sort by score desc
        Session.set "sort_order", # sort by name
          name: 1
          score: -1
      else
        Session.set "sort_order", # sort by score desc
          score: -1
          name: 1

    'click input.randomScore': ->
      resetScores()

    'click input.addButton': ->
      new_player_name = document.getElementById("newPlayer").value.trim()
      if Validation.valid_name new_player_name
        addScientist new_player_name

    'click input.deleteButton': ->
      removeScientist()


  Template.player.events =
    'click': ->
      Session.set "selected_player", @_id


# On server startup, create some players if the database is empty.
if Meteor.isServer
  Meteor.startup ->
    resetTable()