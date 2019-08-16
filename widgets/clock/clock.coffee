class Dashing.Clock extends Dashing.Widget

  ready: ->    
    @sprintEnd = new Date(@get('sprintEnd')) || new Date()
    setInterval(@startTime, 500)
    

  startTime: =>
    today = new Date()

    h = today.getHours()%12
    m = today.getMinutes()
    s = today.getSeconds()
    m = @formatTime(m)
    s = @formatTime(s)
    @set('time', h + ":" + m + ":" + s)
    @set('date', today.toDateString())
    @set('endDate', @sprintEnd.toDateString())

    days = Math.round ((@sprintEnd.getTime() - today.getTime()) / (1000 * 60 * 60 * 24))

    @set('daysRemaining', days + ' Days Remaining')


  formatTime: (i) ->
    if i < 10 then "0" + i else i

  onData: (data) ->
    @sprintEnd = new Date(data.sprintEnd)
    @startTime()
