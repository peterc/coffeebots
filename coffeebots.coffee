FPS = 45
MIN_DISTANCE_BETWEEN = 100
SPRITES = ['yellow.png', 'red.png', 'purple.png', 'green.png', 'blue.png']
DEGREES_IN_ONE_RADIAN = 57.295800000006835
MAX_PLAYERS = 5
BOT_FILES = ['simple.bot']

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
		
	detectRobotCrashes: ->
		for robot1 in @robots
			for robot2 in @robots
				if (robot1.distanceTo(robot2) < 32) && (robot1 != robot2)
					robot1.health -= 0.1
		
	tick: ->
		@ctx.clearRect(0, 0, @width, @height)
		for robot in @robots
			if robot.alive
				dataRow = $("#bots .bot#{robot.rid} .stats")
				if robot.health > 0
					robot.work()
					robot.move()
					@detectRobotCrashes()
					dataRow.find('.health SPAN').text(Math.floor(robot.health))
					dataRow.find('.speed SPAN').text(robot.speed.toFixed(1))
					dataRow.find('.heading SPAN').text(robot.heading)
				else
					robot.alive = false
					Robot.numberAlive -= 1
					if Robot.numberAlive == 0
						window.arena.pause()
					robot.sprite.src = '/images/white.png'
					dataRow.text('DEAD!!!').addClass('dead')
		for projectile in @projectiles
			if projectile.active
				projectile.move()
			if projectile.exploding
				for robot in @robots
					robot.health -= 20 if Math.floor(Math.sqrt(Math.pow(robot.x - projectile.x, 2) + Math.pow(robot.y - projectile.y, 2))) < 100
		@draw()
		setTimeout window.tick, 1000 / FPS if !@paused

	draw: =>
		for robot in @robots
			if robot.ready
				@ctx.drawImage robot.sprite, robot.x, robot.y
		for projectile in @projectiles
			if projectile.active
				@ctx.drawImage projectile.sprite, projectile.x, projectile.y
			if projectile.exploding
				@ctx.drawImage projectile.explosion, projectile.x - 50, projectile.y - 50
				projectile.exploding = false
			

class Robot
	this.numberAlive = 0
	importCode: (code) ->
		code = "window.robot = {\n#{code}}\n"
		CoffeeScript.eval code
		@work = window.robot.work
		@name = window.robot.name
		@creator = window.robot.creator
		@data = window.robot.data
		$("#bots .bot#{@rid} .name").text(@name)
	constructor: (options) ->
		@name = ''
		@rid = options.rid
		@ready = false
		@sprite = new Image
		@sprite.src = "images/#{options.sprite}"
		@x = 0
		@y = 0
		@alive = true
		Robot.numberAlive += 1
		@heading = 0
		@speed = 0
		@health = 100
		@targetSpeed = 0
		@width = 32
		@height = 32
		@codeLoaded = false
		@sprite.onload = =>
			@width = @sprite.width
			@height = @sprite.height
			@ready = true
		if options.code
			if options.code.match /^\//
				$.get options.code,
					{},
					(data) =>
						@importCode(data)
			else
				@importCode(options.code)
	move: ->
		dx = Math.sin((@heading + 90) / DEGREES_IN_ONE_RADIAN) * @speed
		dy = Math.cos((@heading + 90) / DEGREES_IN_ONE_RADIAN) * @speed
		if Math.round(@speed) != Math.round(@targetSpeed)
			if @speed < @targetSpeed
				@speed += 0.1
			else
				@speed -= 0.1
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
	shoot: (heading, range) =>
		window.arena.projectiles.push(new Projectile { robot: this, heading: heading, range: range })
	scan: (heading, resolution) ->
		for robot in window.arena.robots
			if robot != this
				angle = (360 + (Math.atan2(robot.x - @x, robot.y - @y) * 57.295)) % 360
				if angle > (heading - resolution) && angle < (heading + resolution)
					return Math.floor(Math.sqrt(Math.pow(robot.x - @x, 2) + Math.pow(robot.y - @y, 2)))
		return 0
		
	
class Projectile
	constructor: (options) ->
		@robot = options.robot
		@x = options.robot.x
		@y = options.robot.y
		@heading = options.heading
		@speed = 5
		@range = options.range
		@active = true
		@exploding = false
		@sprite = new Image
		@sprite.src = "images/projectile.png"
		@explosion = new Image
		@explosion.src = "images/explosion.png"
	move: ->
		dx = Math.sin((@heading + 90) / DEGREES_IN_ONE_RADIAN) * @speed
		dy = Math.cos((@heading + 90) / DEGREES_IN_ONE_RADIAN) * @speed
		@x += dx
		@y += dy
		@range -= @speed
		if @range < 0			
			@active = false
			@exploding = true
		if @x < 0 || @x > window.arena.width || @y < 0 || @y > window.arena.height
			@active = false
		
		
$ ->
	window.arena = new Arena
	arena = window.arena
	$('#controls button').attr('disabled', true)
	window.globs = {}
	botId = 0
	updateControls = ->
		$('#controls button').attr('disabled', false) if arena.robots.length > 1
		$('button#addbot').attr('disabled', true) if arena.robots.length == MAX_PLAYERS	
	addbot = (code = '/bots/simple.bot') ->
		sprite = SPRITES[botId]
		r = new Robot { sprite: sprite, code: code, rid: botId }
		botDataRow = $('#bots .bot:first').clone().show().addClass("bot#{r.rid}");
		$(botDataRow).find('img:first').attr('src', "/images/#{sprite}");
		$('#bots').append(botDataRow);
		botId += 1
		arena.addRobot(r)
		updateControls()
		setTimeout arena.draw, 50
		# Slightly hacky cheat because I can't be arsed with hooking up the callback atm
		setTimeout arena.draw, 250
	$('button#addbot').click =>
		addbot()
	$('button#run').click ->
		$(this).attr('disabled', true)
		$('button#addbot').attr('disabled', true)
		arena.run()
	$('button#reset').click ->
		$('#controls button').attr('disabled', true)
		$('button#addbot').attr('disabled', false)
		botId = 0
		arena.reset()
		# Nasty hack just for 'get the hack done' sakes..
		window.location.reload()
	$('button#pause').click ->
		if arena.paused
			arena.unpause()
			$(this).text('Pause')
		else
			arena.pause()
			$(this).text('Resume')
	addbot('/bots/simple.bot')
	addbot('/bots/simple2.bot')
	addbot('/bots/bonkers.bot')
	addbot('/bots/bonkers.bot')
	