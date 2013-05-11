cameraEnabled = false

videoInput = document.createElement("video")
videoInput.setAttribute "loop", "true"
videoInput.setAttribute "autoplay", "true"
videoInput.setAttribute "width", "320"
videoInput.setAttribute "height", "240"
document.body.appendChild videoInput

# messaging stuff
gUMnCamera = ->
  gumSupported = true
  cameraEnabled = true
  messages = ["trying to detect face", "please wait"]

enableStart = ->
  document.getElementById("but").className = ""
  
  # change button to display "start"
  document.getElementById("start").innerHTML = "START"
  
  # add eventlistener to button
  document.getElementById("start").addEventListener "click", start, true

document.addEventListener "headtrackrStatus", ((e) ->
  switch e.status
    when "camera found"
      gUMnCamera()
    when "no getUserMedia"
      noGUM()
    when "no camera"
      noCamera()
    when "found"
      enableStart()
), false

# Face detection setup
canvasInput = document.createElement("canvas") # compare
canvasInput.setAttribute "width", "320"
canvasInput.setAttribute "height", "240"

htracker = new headtrackr.Tracker
  smoothing: false
  fadeVideo: true
  ui: false

htracker.init videoInput, canvasInput
htracker.start()
canvasInput = document.createElement("canvas") # ident
canvasInput.setAttribute "width", videoInput.clientWidth
canvasInput.setAttribute "height", videoInput.clientHeight
document.body.appendChild canvasInput
canvasInput.style.position = "absolute"
canvasInput.style.top = "60px"
canvasInput.style.left = "10px"
canvasInput.style.zIndex = "1002"
canvasInput.style.display = "block"
canvasCtx = canvasInput.getContext("2d")
canvasCtx.strokeStyle = "#999"
canvasCtx.lineWidth = 2
drawIdent = (cContext, x, y) ->
  
  # normalise values
  x = (x / 320) * canvasInput.width
  y = (y / 240) * canvasInput.height
  
  # flip horizontally
  x = canvasInput.width - x
  
  # clean canvas
  cContext.clearRect 0, 0, canvasInput.width, canvasInput.height
  
  # draw rectangle around canvas
  cContext.strokeRect 0, 0, canvasInput.width, canvasInput.height
  
  # draw marker, from x,y position
  cContext.beginPath()
  cContext.moveTo x - 5, y
  cContext.lineTo x + 5, y
  cContext.closePath()
  cContext.stroke()
  cContext.beginPath()
  cContext.moveTo x, y - 5
  cContext.lineTo x, y + 5
  cContext.closePath()
  cContext.stroke()

document.addEventListener "facetrackingEvent", ((e) ->
  drawIdent canvasCtx, e.x, e.y
), false
document.addEventListener "headtrackingEvent", ((e) ->
  game.mouseX = e.x * 20
  game.mouseY = -e.y * 20
), false
