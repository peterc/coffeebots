FPS = 60
MIN_DISTANCE_BETWEEN = 100
SPRITES = ['yellow.png', 'red.png', 'purple.png', 'green.png', 'blue.png']
DEGREES_IN_ONE_RADIAN = 57.295800000006835

class Arena
	constructor: (@canvasId = 'arena') ->
		@reset()

	reset: ->
		@robots = []
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
			robot.move()
		@draw()
		setTimeout window.tick, 1000 / FPS if !@paused

	draw: ->
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
		@heading = 45
		@speed = 0.5
		@targetSpeed = 2
		@width = 32
		@height = 32
		@sprite.onload = =>
			@width = @sprite.width
			@height = @sprite.height
			@ready = true
	move: ->
		dx = Math.sin((@heading + 90) / DEGREES_IN_ONE_RADIAN) * @speed
		dy = Math.cos((@heading + 90) / DEGREES_IN_ONE_RADIAN) * @speed
		if @speed != @targetSpeed
			if @speed < @targetSpeed
				@speed += 0.1
			else
				@speed -= 0.2
		@x += dx
		@y += dy
	distanceTo: (otherbot) ->
		Math.floor(Math.sqrt(Math.pow(otherbot.x - @x, 2) + Math.pow(otherbot.y - @y, 2)))
	
	
class Projectile
	constructor: (options) ->
		@robot = options.robot
		@active = false
		@speed = 1
		@angle = options.angle
	
		
$ ->
	arena = new Arena
	colorId = 0
	$('button#addbot').click ->
		r = new Robot { name: 'Rover', sprite: SPRITES[colorId] }
		arena.addRobot(r)
		colorId += 1
		$(this).attr('disabled', true) if arena.robots.length > 4
	$('button#run').click ->
		arena.run()
	$('button#reset').click ->
		colorId = 0
		arena.reset()
	$('button#pause').click ->
		if arena.paused
			arena.unpause()
			$(this).text('Pause')
		else
			arena.pause()
			$(this).text('Resume')
	