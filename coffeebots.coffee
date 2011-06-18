FPS = 60
MIN_DISTANCE_BETWEEN = 100
SPRITES = ['yellow.png', 'red.png', 'purple.png', 'green.png', 'blue.png']
DEGREES_IN_ONE_RADIAN = 57.295800000006835
MAX_PLAYERS = 5

class Arena
	constructor: (@canvasId = 'arena') ->
		@reset()

	reset: ->
		@robots = []
		@projectiles = []
		@paused = true
		@canvas = $("##{@canvasId}")
		@ctx = @canvas.get(0).getContext "2d"
		@width = @canvas.width()
		@height = @canvas.height()
		@tick()
		
	run: ->
		@canvas.show()
		@paused = false
		window.tick = =>
			@tick()
		@tick()
		
	pause: ->
		@paused = true
		
	unpause: ->
		@paused = false
		@tick()

	addRobot: (robot) ->
		loop
			min = 1000
			robot.x = Math.floor(Math.random() * (@width - 32))
			robot.y = Math.floor(Math.random() * (@height - 32))
			break if @robots.length is 0
			for otherrobot in @robots
				next if otherrobot is robot
				distance = robot.distanceTo(otherrobot)
				if distance < min
					min = distance
			break if (@robots.length > 0) && (min > MIN_DISTANCE_BETWEEN)
		@robots.push(robot)
		
	tick: ->
		@ctx.clearRect(0, 0, @width, @height)
		for robot in @robots		
			robot.work()
			robot.move()
		for projectile in @projectiles
			projectile.move()
		@draw()
		setTimeout window.tick, 1000 / FPS if !@paused

	draw: =>
		for robot in @robots
			if robot.ready
				@ctx.drawImage robot.sprite, robot.x, robot.y
			

class Robot
	constructor: (options) ->
		@name = options.name
		@ready = false
		@sprite = new Image
		@sprite.src = "images/#{options.sprite}"
		@x = 0
		@y = 0
		@heading = 0
		@speed = 0
		@strength = 100
		@targetSpeed = 0
		@width = 32
		@height = 32
		@codeLoaded = false
		@sprite.onload = =>
			@width = @sprite.width
			@height = @sprite.height
			@ready = true
		if options.load
			$.get options.load,
				{},
				(data) =>
					code = "window.robot = {\n#{data}}\n"
					CoffeeScript.eval code
					@work = window.robot.work
					@name = window.robot.name
					@creator = window.robot.creator
					@data = window.robot.data
	move: ->
		dx = Math.sin((@heading + 90) / DEGREES_IN_ONE_RADIAN) * @speed
		dy = Math.cos((@heading + 90) / DEGREES_IN_ONE_RADIAN) * @speed
		if @speed != @targetSpeed
			if @speed < @targetSpeed
				@speed += 0.1
			else
				@speed -= 0.2
		if ((@x + dx) < (arena.width - @width)) && (@x + dx > 0)
			@x += dx
		else
			@speed = 0
		if ((@y + dy) < (arena.height - @height)) && (@y + dy > 0)
			@y += dy
		else
			@speed = 0
	distanceTo: (otherbot) ->
		Math.floor(Math.sqrt(Math.pow(otherbot.x - @x, 2) + Math.pow(otherbot.y - @y, 2)))
	rand: (limit) ->
		Math.floor(Math.random() * limit)
	drive: (heading, speed) ->
		speed = 0 if speed < 0
		speed = 4 if speed > 4
		@targetSpeed = speed
		@heading = heading
		
	
	
class Projectile
	constructor: (options) ->
		@robot = options.robot
		@active = false
		@speed = 1
		@x = 0
		@y = 0
		@heading = 0
		@speed = 0
		@ttl = 0
		@angle = options.angle
	move: ->
		
	
		
$ ->
	arena = new Arena
	$('#controls button').attr('disabled', true)
	window.globs = {}
	colorId = 0
	$('button#addbot').click ->
		r = new Robot { name: 'simple', sprite: SPRITES[colorId], load: '/bots/simple.bot' }
		arena.addRobot(r)
		colorId += 1
		$('#controls button').attr('disabled', false) if arena.robots.length > 1
		$(this).attr('disabled', true) if arena.robots.length == MAX_PLAYERS
		setTimeout arena.draw, 50
		setTimeout arena.draw, 150
	$('button#run').click ->
		arena.run()
	$('button#reset').click ->
		$('#controls button').attr('disabled', true)
		$('button#addbot').attr('disabled', false)
		colorId = 0
		arena.reset()
	$('button#pause').click ->
		if arena.paused
			arena.unpause()
			$(this).text('Pause')
		else
			arena.pause()
			$(this).text('Resume')
	