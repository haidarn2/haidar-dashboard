class Dashing.Clock extends Dashing.Widget

  ready: ->
    setInterval(@startTime, 500)

  startTime: =>
    today = new Date()
    @set('time', today.toLocaleTimeString())
    @set('date', today.toDateString())