@sensList = ['low', 'default', 'high', 'very high', 'extreme']
@sensValue = [1, 1.3, 1.6, 2, 4]

gameReset = ->
  @health = 100
  @speed = 0
  @score = 0
  @status = 1
  @shipX = 0
  @shipY = 0
  @view = 1
  @maxSpeed = 52
  @speedLimit = 100
  @zCamera2 = 0

  for obj in @objs
    obj.position.x = Math.random() * 5000 - 2500
    obj.position.y = -300

  $('#score').html score

introReset = (gameCompleted) ->
  @speed = 0
  @view = 2
  @status = 0

  hiScore = localStorage.getItem 'fk2hiscore'
  if not hiScore?
    hiScore = 0

  $('#score').html "Hi-Score: #{hiScore}"
  $('#hud').hide()
  $('#like').show()








