class Game
  constructor: ->
    @status = 0
    @health = @speed = @maxSpeed = @speedLimit = @view = @tm = @score = @hiScore = null
    @shipX = @shipY = 0
    @fullscreen = @windowHalfX = @windowHalfY = @windowX = @windowY = null
    @mx = @my = 0
    @light1 = @light2 = null
    @sensitivity = 1
    @sen = 1
    @autoSwitch = 1
    @controls = 0
    @yInvert = 0
    @keyUp = @keyDown = @keyLeft = @keyRight = @keySpace = false
    @container = @ctx = null
    @camera = @scene = @renderer = null
    @geometry = @dust = null
    @group2 = @group2color = null
    @ship = null
    @mouseX = @mouseY = @faceX = @faceY = 0
    @particles = new Array()
    @bullet = null
    @objs = @background = null
    @fov = 80
    @fogDepth = 3500
    @tm = @dtm = @track = @nextFrame = @phase = null
    @zCamera = @zCamera2 = 0
    @p = new Array()
    @sensList = ['low', 'default', 'high', 'very high', 'extreme']
    @sensValue = [1, 1.3, 1.6, 2, 4]
    @controlsList = ['mouse', 'arrows / WASD', 'head tracking']

    @introReset false
    @init()
    @animate()
  
    $('#start').on 'click', =>
      @gameReset()
      $('#hud').show()
      $('#score').show()
      $('#like').hide()
      $('#panel1').hide()
      $('#feedback').hide()
  
    $('#options').on 'click', =>
      $('#panel1').hide()
      $('#panel2').show()
  
    $('#op_sensitivity').on 'click', =>
      @sensitivity += 1
      @sensitivity %= 4
      @updateUI()
  
    $('#op_close').on 'click', =>
      $('#panel2').hide()
      $('#panel1').show()
  
    $('#op_1stperson').on 'click', =>
      @autoSwitch = 1 - @autoSwitch
      @updateUI()
  
    $('#op_controls').on 'click', =>
      @controls += 1
      @controls %= 3
      @updateUI()
  
    $('#op_yinvert').on 'click', =>
      @yInvert = 1 - @yInvert
      @updateUI()

  gameReset: ->
    console.log 'gameReset'
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
  
    for obj in @objs.children
      obj.position.x = Math.random() * 5000 - 2500
      obj.position.y = -300
  
    $('#score').html @score
  
  introReset: (gameCompleted) ->
    console.log 'introReset'
    @speed = 0
    @view = 2
    @status = 0
  
    @hiScore = @get 'fk2hiscore', 0
    if gameCompleted and @hiScore < @score
      @set 'fk2hiscore', @score
  
    $('#score').html "Hi-Score: #{@hiScore}"
    $('#hud').hide()
    $('#like').show()
    $('#panel1').show()
    $('#feedback').show()
  
  onWindowResize: =>
    @windowX = window.innerWidth
    @windowY = window.innerHeight
    @windowHalfX = @windowX / 2
    @windowHalfY = @windowY / 2
    @camera.aspect = @windowX / @windowY
    @camera.updateProjectionMatrix()
    @renderer.setSize @windowX, @windowY
    @fullscreen = @windowX == window.outerWidth
  
  get: (id, def) ->
    value = localStorage.getItem id
    value = def unless value?
    return parseInt(value)
  
  set: (id, value) ->
    value = 0 unless value?
    localStorage.setItem id, value
  
  updateUI: ->
    $('#op_sensitivity').html "controls sensitivity : #{@sensList[@sensitivity]}"
    $('#op_1stperson').html "automatic 1st/3rd person : #{if @autoSwitch then 'yes' else 'no'}"
    $('#op_controls').html "controls : #{@controlsList[@controls]}"
    $('#op_yinvert').html  "invert Y axis : #{if @yInvert == 0 then 'no' else 'yes'}"
  
    @set 'fk2sensitivity', @sensitivity
    @set 'fk2autoswitch', @autoSwitch
    @set 'fk2controls', @controls
    @set 'fk2yinvert', @yInvert
  
  drawSector: (centerX, centerY, r, startingAngle, endingAngle, color) ->
    @ctx.save()
  
    arcSize = endingAngle - startingAngle
  
    @ctx.beginPath()
    @ctx.moveTo centerX, centerY
    @ctx.arc centerX, centerY, r * 0.65, 0, Math.PI * 2, false
    @ctx.closePath()
    @ctx.fillStyle = '#000000'
    @ctx.fill()
  
    @ctx.beginPath()
    @ctx.moveTo centerX, centerY
    @ctx.arc centerX, centerY, r * 0.60, 0, Math.PI * 2, false
    @ctx.closePath()
    @ctx.fillStyle = '#ff0000'
    @ctx.fill()
  
    if @health > 0
      @ctx.beginPath()
      @ctx.moveTo centerX, centerY
      @ctx.arc centerX, centerY, r * 0.60 * (@health / 100), 0, Math.PI * 2, false
      @ctx.closePath()
      @ctx.fillStyle = '#ffffff'
      @ctx.fill()
  
    @ctx.restore()
  
  rgbColor: (r, g, b) ->
    b + (256 * g)|0 + (256 * 256 * r)|0

  fireWeapon: ->
    return if @bullet?

    texture = THREE.ImageUtils.loadTexture('img/spark.png')
    @bullet = new THREE.Object3D()
    attributes =
      startSize: []
      startPosition: []
      randomness: []

    total = 200
    range = 100

    for i in [0...total]
      material = new THREE.SpriteMaterial
        map: texture
        useScreenCoordinates: false
        color: 0xffffff
      sprite = new THREE.Sprite(material)
      sprite.scale.set 32, 32, 1.0
      sprite.position.set(Math.random() - 0.5, Math.random() - 0.5, Math.random() - 0.5)
      sprite.position.setLength(range * (Math.random() * 0.1 + 0.9))
      sprite.material.color.setHSL(Math.random(), 0.9, 0.7)
      sprite.material.blending = THREE.AdditiveBlending
      @bullet.add sprite
      attributes.startPosition.push sprite.position.clone()
      attributes.randomness.push Math.random()

    @bullet.position =
      x: @ship.position.x
      y: @ship.position.y
      z: @ship.position.z - 100

    @scene.add @bullet
  
  generateCubesRing: (cubes, y, radius, spreading, depthSpread, sizeVariance) ->
    mergedGeo = new THREE.Geometry()
    geometry = new THREE.CubeGeometry(10, 10, 10)
    mesh = new THREE.Mesh(geometry)
  
    for i in [0...cubes]
      mesh.scale.x = mesh.scale.y = mesh.scale.z = 1 + Math.random() * sizeVariance
  
      mesh.position.x = Math.cos(i / cubes * Math.PI * 2) * radius + Math.random() * spreading - spreading / 2
      mesh.position.y = y + Math.random() * depthSpread
      mesh.position.z = Math.sin(i / cubes * Math.PI * 2) * radius + Math.random() * spreading - spreading / 2
  
      mesh.rotation.x = Math.random() * 360 * (Math.PI / 180)
      mesh.rotation.y = Math.random() * 360 * (Math.PI / 180)
      THREE.GeometryUtils.merge mergedGeo, mesh
  
    mergedGeo
  
  generateObstacle: ->
    geometry = new THREE.SphereGeometry 50, 5, 3
    material = new THREE.MeshPhongMaterial
      color: 0xffffff
      specular: 0xffffff
      shininess: 150
      opacity: 1
      shading: THREE.FlatShading
    mesh = new THREE.Mesh(geometry, material)
  
    mesh.matrixAutoUpdate = true
    mesh.updateMatrix()
    @objs.add mesh
  
    mesh
  
  generateShip: ->
    mergedGeo = new THREE.Geometry()
    geometry_cube = new THREE.CubeGeometry(50, 50, 50)
    geometry_cyl = new THREE.CylinderGeometry(50, 20, 50, 8, 1)
    geometry_cyl2 = new THREE.CylinderGeometry(50, 40, 50, 4, 1)
    material = new THREE.MeshPhongMaterial(
      color: 0xffffff
      specular: 0xffffff
      shininess: 50
      opacity: 1
      shading: THREE.FlatShading
    )
    
    # Building the space ship, LEGO style!
    mesh = new THREE.Mesh(geometry_cube, material)
    mesh2 = new THREE.Mesh(geometry_cyl, material)
    mesh3 = new THREE.Mesh(geometry_cyl2, material)
    
    # body
    mesh2.position.x = 0
    mesh2.position.y = 0
    mesh2.position.z = 0
    mesh2.rotation.x = Math.PI / 2
    mesh2.rotation.y = Math.PI / 2
    mesh2.scale.x = 0.25
    THREE.GeometryUtils.merge mergedGeo, mesh2
    
    # siedewings
    mesh3.position.x = 0
    mesh3.position.y = 0
    mesh3.position.z = 16
    mesh3.rotation.x = Math.PI / 2
    mesh3.rotation.y = Math.PI / 2
    mesh3.scale.x = 0.1
    mesh3.scale.y = 0.5
    mesh3.scale.z = 1.6
    THREE.GeometryUtils.merge mergedGeo, mesh3
    
    # wings up
    mesh.position.y = 15
    mesh.position.z = 12
    mesh.scale.x = 0.015
    mesh.scale.y = 0.4
    mesh.scale.z = 0.25
    mesh.rotation.y = 0
    mesh.rotation.x = -Math.PI / 10
    mesh.position.x = 20
    mesh.rotation.z = -Math.PI / 20
    THREE.GeometryUtils.merge mergedGeo, mesh
    mesh.position.x = -20
    mesh.rotation.z = Math.PI / 20
    THREE.GeometryUtils.merge mergedGeo, mesh
    mergedGeo.computeFaceNormals()
    group = new THREE.Mesh(mergedGeo, material)
    group.matrixAutoUpdate = true
    group.updateMatrix()
    @scene.add group

    scale = 0.08
    enginepng = THREE.ImageUtils.loadTexture("img/engine_small.png")
    enginemat = new THREE.SpriteMaterial
      map: enginepng
      color: 0xffffff
      fog: true
      useScreenCoordinates: false
    @engine_lt = new THREE.Sprite enginemat.clone()
    @engine_lt.position.set -20, 0, 35
    @engine_lt.scale.set 128, 128, 1.0
    group.add @engine_lt
    @engine_rt = new THREE.Sprite enginemat.clone()
    @engine_rt.position.set 20, 0, 35
    @engine_rt.scale.set 128, 128, 1.0
    group.add @engine_rt
    group
  
  onKeyDown: (event) =>
    switch event.keyCode
      when 38, 87 then @keyUp = true
      when 40, 83 then @keyDown = true
      when 37, 65 then @keyLeft = true
      when 39, 68 then @keyRight = true
      when 27 # ES@C
        @materials.opacity = 0
        $('#body').css 'background-color', '#000'
        @introReset false
  
  onKeyUp: (event) =>
    switch event.keyCode
      when 38, 87 then @keyUp = false
      when 40, 83 then @keyDown = false
      when 37, 65 then @keyLeft = false
      when 39, 68 then @keyRight = false
  
  onKeyPress: (event) =>
    switch event.keyCode
      when 32 # space
        @fireWeapon()
  
  onDocumentMouseMove: (event) =>
    if @controls == 0
      @mouseX = (event.clientX - @windowHalfX) / @windowX * 2
      @mouseY = (event.clientY - @windowHalfY) / @windowY * 2

  init: =>
    @sensitivity = @get 'fk2sensitivity', 1
    @autoSwitch = @get 'fk2autoswitch', 1
    @controls = @get 'fk2controls', 2
    @yInvert = @get 'fk2yinvert', 0
    videoInput = document.getElementById('inputVideo')
    canvasInput = document.getElementById('inputCanvas')

    $(window).on 'keyup', @onKeyUp
    $(window).on 'keydown', @onKeyDown
    $(window).on 'keypress', @onKeyPress
    $(window).on 'mousemove', @onDocumentMouseMove

    @container = $('div')
    $('body').append @container
  
    @camera = new THREE.PerspectiveCamera 90, window.innerWidth / window.innerHeight, 1, @fogDepth
    @camera.position.z = 0
  
    @scene = new THREE.Scene()
  
    @light1 = new THREE.DirectionalLight 0xddddff
    @light1.position.set 2, -3, 1.5
    @light1.position.normalize()
    @scene.add @light1
  
    @light2 = new THREE.DirectionalLight()
    @light2.color.setHSL Math.random(), 0.75, 0.5
    @light2.position.set -1.5, 2, 0
    @light2.position.normalize()
    @scene.add @light2
  
    @scene.fog = new THREE.Fog 0x000000, 1, @fogDepth
  
    @dust = new THREE.Geometry()
    for i in [0...2000]
      r = 850 + Math.random() * 2100
      a = Math.random() * 2 * Math.PI
      vector = new THREE.Vector3 Math.cos(a) * r, Math.sin(a) * r, Math.random() * @fogDepth
      @dust.vertices.push(new THREE.Vector3(vector))
  
    @materials = new THREE.ParticleBasicMaterial
      size: 15
      opacity: 0.1
    @materials.color.setRGB 1, 1, 1
  
    @particles[0] = new THREE.ParticleSystem @dust, @materials
    @particles[0].position.z = 0
    @scene.add @particles[0]
  
    @particles[1] = new THREE.ParticleSystem @dust, @materials
    @particles[1].position.z = -@fogDepth
    @scene.add @particles[1]
  
    @background = new THREE.Object3D()
    @scene.add @background
  
    mesh_tmp = @generateCubesRing 300, 0, 1200, 200, 1500, 5
    mesh_tmp.computeFaceNormals()
    @group2color = new THREE.MeshPhongMaterial
      color: 0xff0000
      specular: 0xffffff
      shininess: 150
      shading: THREE.FlatShading
    @group2 = new THREE.Mesh mesh_tmp, @group2color
    @group2color.color.setRGB 0, 1, 0
    @group2.matrixAutoUpdate = true
    @group2.updateMatrix()
    @background.add @group2
  
    @group2.position.z = -@fogDepth
    @group2.rotation.x = Math.PI / 2
  
    @objs = new THREE.Object3D()
    @scene.add @objs
  
    for i in [0...200]
      obs = @generateObstacle()
      obs.position.z = -i * (@fogDepth / 200)
      obs.position.x = Math.random() * 5000 - 2500
      obs.position.y = Math.random() * 3000 - 1500
      obs.rotation.x = Math.random() * Math.PI
      obs.rotation.y = Math.random() * Math.PI
  
    @ship = @generateShip()
  
    @renderer = new THREE.WebGLRenderer
      antialias: true
  
    canvas = $('#hud')[0]
    @ctx = canvas.getContext '2d'
  
    @renderer.autoClear = true
    @renderer.sortObjects = false
    @container.append @renderer.domElement
  
    $(window).resize @onWindowResize
    @onWindowResize()
  
    @tm = (new Date).getTime()
    @track = 10000
    @nextFrame = 0
    @phase = 1
  
    @updateUI()
  
  animate: =>
    requestAnimationFrame @animate
  
    ntm = (new Date).getTime()
    @dtm = ntm - @tm
    @tm = ntm
  
    if @status == 0
      @renderIntro()
    else
      @renderGame()
  
  renderIntro: ->
    @clight = (@tm / 1000000) % 1
    @light2.color.setHSL @clight, 0.4, 0.5
  
    @zCamera2 = @zCamera = -220
    @xRatio = 1
    @yRatio = 1
  
    @camera.position =
      x: @shipX * @xRatio
      y: @shipY * @yRatio
      z: @zCamera
  
    @group2.position.z += @speed
    @group2.rotation.y = - new Date().getTime() * 0.0004
  
    if @group2.position.z > 0
      @group2.position.z = -@fogDepth
      @group2color.color.setHSL Math.random(), 1, 0.5
  
    @camera.lookAt(new THREE.Vector3(@shipX * 0.5, @shipY * 0.25, -1000))
  
    for obj in @objs.children
      obj.rotation.x += 0.01
      obj.rotation.y += 0.005
  
      obj.position.z += @speed
  
      if obj.position.z > 100
        obj.position.z -= @fogDepth
        obj.position.x = Math.random() * 3000 - 1500
        obj.position.y = Math.random() * 3000 - 1500
  
    @renderer.render @scene, @camera
    @speed = 0.3
  
    @fov = 110
    @camera.fov = @fov
    @camera.updateProjectionMatrix()
  
  renderGame: ->
    if @speed > 0
      @clight = @speed / @speedLimit
      $('#body').css 'background-color', '#000'
    else
      @clight = 0
      tmp = -Math.floor(Math.random() * @speed * 100)
      $('#body').css 'background-color', "rgb(#{tmp}, #{tmp/2}, 0)"
  
    @light2.color.setHSL @clight, 0.3, 0.5
  
    switch @controls
      when 0
        @mx = Math.max(Math.min(@mouseX * @sen, 1), -1)
        @my = Math.max(Math.min(@mouseY * @sen, 1), -1)
      when 1
        if @keyUp then @my -= 0.002 * @dtm * @sen
        if @keyDown then @my += 0.002 * @dtm * @sen
        if @keyLeft then @mx -= 0.003 * @dtm * @sen
        if @keyRight then @mx += 0.003 * @dtm * @sen
        @mx = Math.max(Math.min(@mx, 1), -1)
        @my = Math.max(Math.min(@my, 1), -1)
      when 2
        @mx = Math.max(Math.min(@faceX * @sen, 1), -1)
        @my = Math.max(Math.min(@faceY * @sen, 1), -1)
  
    if @yInvert == 1 then @my = -@my
  
    @shipX = @shipX - (@shipX - @mx * 700) / 4
    @shipY = @shipY - (@shipY - (-@my) * 250) / 4
  
    if @autoSwitch
      if @speed < 15
        @view = 1
        @zCamera2 = 0
      else
        @view = 2
        @zCamera2 = -220
  
    if @view == 1
      @xRatio = 1.1
      @yRatio = 0.5
    else
      @xRatio = 1
      @yRatio = 1
  
    @zCamera = @zCamera - (@zCamera - @zCamera2)  / 10
    @camera.position =
      x: @shipX * @xRatio
      y: @shipY * @yRatio
      z: @zCamera
  
    @ship.position.x = @shipX
    @ship.position.y = @shipY
    @ship.position.z = -200
  
    @ship.rotation.z = -@shipX / 1000
  
    @group2.position.z += @speed
    @group2.rotation.y = - new Date().getTime() * 0.0004
  
    if @group2.position.z > 0
      @group2.position.z = -4000
      @group2color.color.setHSL @clight, 1, 0.5
  
    @camera.lookAt(new THREE.Vector3(@shipX * 0.5, @shipY * 0.25, -1000))
  
    @particles[0].position.z += @speed
    if @particles[0].position.z > 100
      @particles[0].position.z -= @fogDepth * 2
  
    @particles[1].position.z += @speed
    if @particles[1].position.z > 100
      @particles[1].position.z -= @fogDepth * 2

    if @bullet?
      @bullet.position.z -= @speedLimit / 2
      if @bullet.position.z < -10000
        @scene.remove @bullet
        @bullet = null
      else
        @bullet.rotation.x -= 0.1
        @bullet.rotation.y += 0.03
  
    for obj in @objs.children
      obj.rotation.x += 0.01
      obj.rotation.y += 0.005
      obj.position.z += @speed

      if (@bullet? and Math.abs(@bullet.position.x - obj.position.x) < 100 and Math.abs(@bullet.position.y - obj.position.y) < 100 and Math.abs(@bullet.position.z - obj.position.z) < 100)
        @score += 10
        $('#score').html @score

      if obj.position.z > 100 or (@bullet? and Math.abs(@bullet.position.x - obj.position.x) < 100 and Math.abs(@bullet.position.y - obj.position.y) < 100 and Math.abs(@bullet.position.z - obj.position.z) < 100)
        obj.position.z -= @fogDepth
        @nextFrame++
  
        switch @phase
          when 1 # asteroids
            if Math.random() < 0.97
              obj.position.x = Math.random() * 3000 - 1500
              obj.position.y = Math.random() * 3000 - 1500
            else
              obj.position.x = @ship.position.x
              obj.position.y = @ship.position.y
          when 2, 3
            obj.position.x = Math.cos(@nextFrame / @p[0]) * @p[1] * Math.cos(@nextFrame / @p[2]) * @p[3]
            obj.position.y = Math.sin(@nextFrame / @p[4]) * @p[5] * Math.sin(@nextFrame / @p[6]) * @p[7]
          when 4
            r = Math.cos(@nextFrame / @p[0]) * 2000
            obj.position.x = Math.cos(@nextFrame / @p[1]) * r
            obj.position.y = Math.sin(@nextFrame / @p[1]) * r
          when 5
            if Math.random() < 0.95
              obj.position.x = @ship.position.x
              obj.position.y = @ship.position.y
            else
              obj.position.x = Math.random() * 3000 - 1500
              obj.position.y = Math.random() * 3000 - 1500
  
      # collision check
      if Math.abs(@ship.position.x - obj.position.x) < 100 and Math.abs(@ship.position.y - obj.position.y) < 50 and Math.abs(@ship.position.z - obj.position.z) < 50
        if @speed > 0
          @health -= @speed
        @speed = -3
  
    if @health < 0 and @speed > 0
      @introReset true
  
    @renderer.render @scene, @camera
  
    @speed += @dtm / 300
    if @speed > @maxSpeed
      @speed = @maxSpeed
      @maxSpeed = Math.min(@maxSpeed + (@dtm / 1500), 100)
  
    if @speed > 25
      @score++
      $('#score').html @score
  
    @materials.opacity = @speed / @maxSpeed
  
    @track -= @speed
    if @track < 0
      @track = 5000 + Math.random() * 5000
      @phase = Math.floor(Math.random() * 5) + 1
  
      switch @phase
        when 2 # twirl 1
          @p[0] = Math.random()*3+0.01
          @p[1] = 300+Math.random()*900
          @p[4] = @p[0]
          @p[5] = 300+Math.random()*900
          @p[2] = 8+Math.random()*77
          @p[3] = Math.random()*500
          @p[6] = 8+Math.random()*77
          @p[7] = Math.random()*400
        when 3 # snake
          @p[0] = Math.random()*30+7
          @p[1] = 300+Math.random()*900
          @p[4] = @p[0]
          @p[5] = 300+Math.random()*700
          @p[2] = 8+Math.random()*77
          @p[3] = 200+Math.random()*1000
          @p[6] = 8+Math.random()*77
          @p[7] = 200+Math.random()*1000
        when 4 # plane
          @p[0] = Math.random() * 3 + 0.01
          @p[1] = (Math.random() * 500 + 40) * (if Math.random() > 0.5 then 1 else -1)
  
    @fov = @fov - (@fov - (65 + @speed / 2)) / 4
    @camera.fov = @fov
    @camera.updateProjectionMatrix()
  
    @engine_lt.scale.x = @engine_lt.scale.y = @engine_rt.scale.x = @engine_rt.scale.y = (70 / @fov) / 5
    engop = Math.random() / 10 + 0.9
    @engine_lt.opacity = @engine_rt.opacity = engop
  
    @ctx.clearRect(0, 0, 300, 300)
    sp = @speed / @speedLimit * Math.PI * 2
    if @speed > 0
      @drawSector 50, 50, 50, 0, sp, '#00dd44'
    else
      @drawSector 50, 50, 50, 0, sp, '#992200'
  
$ ->
  window.game = new Game()

