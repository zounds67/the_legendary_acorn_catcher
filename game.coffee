# Totoro's Acorn Catch Game
#
# Welcome! In this game, you help Totoro catch falling acorns!
# Your job is to fill in the functions below to make the game work.
# Look for "YOUR CODE HERE" to find where to write your code.
#
# Good luck and have fun!

# ============================================================
# LootLocker Leaderboard Class - Simple API wrapper
# ============================================================
class LootLocker
  constructor: (@apiKey, @leaderboardKey, @apiDomain) ->
    @sessionToken = null

  init: ->
    fetch "#{@apiDomain}/game/v2/session/guest",
      method: "POST"
      headers: { "Content-Type": "application/json" }
      body: JSON.stringify { game_key: @apiKey, game_version: "1.0.0" }
    .then (response) -> response.json()
    .then (data) =>
      if data.session_token
        @sessionToken = data.session_token
      else
        throw new Error(data.message or "No session token received")
      return data

  setName: (name) ->
    fetch "#{@apiDomain}/game/player/name",
      method: "PATCH"
      headers:
        "Content-Type": "application/json"
        "x-session-token": @sessionToken
      body: JSON.stringify { name: name }

  submitScore: (score) ->
    fetch "#{@apiDomain}/game/leaderboards/#{@leaderboardKey}/submit",
      method: "POST"
      headers:
        "Content-Type": "application/json"
        "x-session-token": @sessionToken
      body: JSON.stringify { score: score }
    .then (response) -> response.json()

  getScores: ->
    fetch "#{@apiDomain}/game/leaderboards/#{@leaderboardKey}/list?count=10",
      method: "GET"
      headers: { "x-session-token": @sessionToken }
    .then (response) -> response.json()
    .then (data) -> data.items or []

class Game
  constructor: ->
    @canvas = document.getElementById('game-canvas')
    @ctx = @canvas.getContext('2d')
    @scoreElement = document.getElementById('score')
    @livesElement = document.getElementById('lives')
    @powerupDisplay = document.getElementById('powerup-display')
    @gameOverElement = document.getElementById('game-over')
    @finalScoreElement = document.getElementById('final-score')
    @restartBtn = document.getElementById('restart-btn')

    # LootLocker setup
    @lootlocker = new LootLocker(
      'dev_d454f8a490d943d9acaa1b88507f9e08',
      'acorncatcher',
      'https://tgb2om7o.api.lootlocker.io'
    )
    @playerName = localStorage.getItem('playerName') or ''
    @registeredName = @playerName  # The name they've already submitted scores with

    # Leaderboard UI elements
    @leaderboardList = document.getElementById('leaderboard-list')
    @nameInput = document.getElementById('player-name-input')
    @submitScoreBtn = document.getElementById('submit-score-btn')
    @leaderboardStatus = document.getElementById('leaderboard-status')

    @init()
    @setupControls()
    @restartBtn.addEventListener 'click', => @restart()
    @submitScoreBtn?.addEventListener 'click', => @handleSubmitScore()

    # Initialize LootLocker session
    @initLeaderboard()

  init: ->
    @score = 0
    @lives = 3
    @gameOver = false
    @fallingObjects = []
    @spawnTimer = 0
    @spawnInterval = 60  # frames between spawns
    @difficulty = 1
    @difficultyTimer = 0

    # Totoro player - this is our character!
    # x and y are the position on the screen
    # width and height are how big Totoro is
    # speed is how fast Totoro moves
    @totoro =
      x: @canvas.width / 2 - 40
      y: @canvas.height - 80
      width: 80
      height: 70
      speed: 6
      baseSpeed: 6
      powered: false
      powerTimer: 0

    # These track which arrow keys are being pressed
    @keys =
      left: false
      right: false

    @updateDisplay()
    @gameOverElement.classList.add('hidden')

  setupControls: ->
    document.addEventListener 'keydown', (e) =>
      return if @gameOver
      switch e.key
        when 'ArrowLeft', 'a'
          @keys.left = true
          e.preventDefault()
        when 'ArrowRight', 'd'
          @keys.right = true
          e.preventDefault()

    document.addEventListener 'keyup', (e) =>
      switch e.key
        when 'ArrowLeft', 'a'
          @keys.left = false
        when 'ArrowRight', 'd'
          @keys.right = false

  # ============================================================
  # FUNCTION 1: Move Totoro
  # ============================================================
  # This function moves Totoro left or right when you press keys.
  #
  # HOW IT WORKS:
  # - @keys.left is true when the left arrow is pressed
  # - @keys.right is true when the right arrow is pressed
  # - @totoro.x is Totoro's position (small number = left side, big number = right side)
  # - @totoro.speed is how many pixels to move (it equals 6)
  #
  # WHAT TO DO:
  # - If left key is pressed, subtract speed from x position
  # - If right key is pressed, add speed to x position
  #
  # EXAMPLE:
  #   To move something left, you subtract: x = x - speed
  #   To move something right, you add: x = x + speed
  # ============================================================
  moveTotoro: ->
    # YOUR CODE HERE
    # Hint: Use "if @keys.left" to check if left is pressed
    # Hint: Use @totoro.x to change position
    # Hint: Use @totoro.speed for how much to move

  
    if @keys.left
      @totoro.x = @totoro.x - @totoro.speed 
    if @keys.right
      @totoro.x = @totoro.x + @totoro.speed 
  # ============================================================
  # FUNCTION 2: Keep Totoro On Screen
  # ============================================================
  # This function stops Totoro from walking off the screen!
  #
  # HOW IT WORKS:
  # - @totoro.x is where Totoro is (left-right position)
  # - @canvas.width is how wide the screen is (400 pixels)
  # - @totoro.width is how wide Totoro is (80 pixels)
  # - The left edge of the screen is 0
  # - The right edge is @canvas.width - @totoro.width
  #
  # WHAT TO DO:
  # - If Totoro goes too far left (x < 0), set x to 0
  # - If Totoro goes too far right, set x to the right edge
  #
  # EXAMPLE:
  #   if @totoro.x < 0
  #     @totoro.x = 0
  # ============================================================
  keepTotoroOnScreen: ->
    # YOUR CODE HERE
    # Hint: Check if @totoro.x is less than 0 (too far left)
    # Hint: Check if @totoro.x is greater than @canvas.width - @totoro.width (too far right)
    if @totoro.x < 0
      @totoro.x = 0
    if @totoro.x > @canvas.width - @totoro.width
      @totoro.x = @canvas.width - @totoro.width

  # ============================================================
  # FUNCTION 3: Move Falling Objects Down
  # ============================================================
  # This function makes all the objects fall down the screen!
  #
  # HOW IT WORKS:
  # - @fallingObjects is a list of all things falling (acorns, dust mites, etc)
  # - Each object has a y position (small = top of screen, big = bottom)
  # - Each object has a speed (how fast it falls)
  #
  # WHAT TO DO:
  # - Go through each object in the list
  # - Add the speed to the y position to make it fall down
  #
  # EXAMPLE:
  #   for obj in @fallingObjects
  #     # do something with obj
  # ============================================================
  moveFallingObjects: ->
    # YOUR CODE HEREfor
    # Hint: Use "for obj in @fallingObjects" to loop through objects
    # Hint: Add obj.speed to obj.y to make it fall down
    for obj in @fallingObjects
      obj.y = obj.y + obj.speed


  # ============================================================
  # FUNCTION 4: Check If Two Things Touch (Collision)
  # ============================================================
  # This function checks if Totoro is touching a falling object.
  # Returns true if they touch, false if they don't.
  #
  # HOW IT WORKS:
  # - 'a' is one object (like Totoro)
  # - 'b' is another object (like an acorn)
  # - Each object has: x, y, width, height
  # - Two rectangles touch if they overlap
  #
  # SIMPLE VERSION (just check x and y):
  # - Objects are close if their x positions are close
  # - AND their y positions are close
  #
  # WHAT TO DO (easy version):
  # - Check if the distance between them is small enough
  # - Return true if they're close, false if they're far
  #
  # HINT: You can check if 'a' overlaps 'b' like this:
  #   - a's right side (a.x + a.width) is past b's left side (b.x)
  #   - AND a's left side (a.x) is before b's right side (b.x + b.width)
  #   - AND same idea for top/bottom with y and height
  # ============================================================
  collides: (a, b) ->
    # YOUR CODE HERE
    # Easy version - just check if they're close:
    #   Check if a.x is close to b.x (within 40 pixels)
    #   AND a.y is close to b.y (within 40 pixels)
    #
    #if a.x - b.x < 10 and a.y - b.y < 10
      #return true
    # Harder version - check if rectangles overlap:
    #   a.x < b.x + b.width and
    #   a.x + a.width > b.x and
    #   a.y < b.y + b.height and
    #   a.y + a.height > b.y
    if a.x < b.x + b.width and a.x + a.width > b.x and a.y < b.y + b.height and a.y + a.height > b.y
      return true
    else
      return false


  # ============================================================
  # FUNCTION 5: Handle What Happens When Totoro Catches Things
  # ============================================================
  # This function decides what happens when Totoro touches something!
  #
  # OBJECT TYPES:
  # - 'acorn' = Good! Add 10 points to score
  # - 'dustmite' = Bad! Lose 1 life
  # - 'catbus' = Power-up! Makes Totoro faster
  #
  # HOW IT WORKS:
  # - obj.type tells you what kind of object it is
  # - @score is the player's score
  # - @lives is how many lives left
  # - @updateDisplay() refreshes the score on screen
  #
  # WHAT TO DO:
  # - If it's an acorn: add 10 to @score
  # - If it's a dustmite: subtract 1 from @lives
  # - Call @updateDisplay() after changing score or lives
  # - If lives reach 0, call @endGame()
  # ============================================================
  handleCatch: (obj) ->
    # YOUR CODE HERE
    # Hint: Use "if obj.type is 'acorn'" to check object type
    # Hint: @score += 10 adds 10 to the score
    # Hint: @lives -= 1 subtracts 1 from lives
    # Hint: Call @updateDisplay() to show the new score
    # Hint: Check if @lives <= 0 and call @endGame() if true
    #@totoro =
    #  x: @canvas.width / 2 - 40
    #  y: @canvas.height - 80
    #  width: 80
    #  height: 70
    #  speed: 6
    #  baseSpeed: 6
    #  powered: false
    #  powerTimer: 0
    if obj.type is 'acorn'
      @score = @score + 10
    if obj.type is 'dustmite'
      @lives = @lives - 1
    if obj.type is 'catbus'
        @totoro.powered = true
        @totoro.speed = @totoro.speed * 2
        @totoro.powerTimer = 1000
        @powerupDisplay.textContent = 'Cat Bus Speed!'
    @updateDisplay()
    if @lives == 0
      @endGame()
  # ============================================================
  # FUNCTION 6: Remove Objects That Fall Off Screen
  # ============================================================
  # This function removes objects that fell past the bottom!
  #
  # HOW IT WORKS:
  # - Objects that go past y = 450 are off the screen
  # - We need to keep only objects that are still visible
  # - We use filter to keep objects where y < 450
  #
  # WHAT TO DO:
  # - Use filter to keep only objects with y less than 450
  #
  # EXAMPLE:
  #   To filter a list and keep only some items:
  #   @myList = @myList.filter (item) -> item.value < 100
  # ============================================================
  removeOffScreenObjects: ->
    # YOUR CODE HERE
    # Hint: @fallingObjects = @fallingObjects.filter (obj) -> ???
    # Hint: Keep objects where obj.y < 450
    # Alternative Hint:  Use a for loop!
    # Create a new array: remObjects = []
    # for obj in @fallingobjects
    #   do something (add obj to remObjects ush remObjects.push obj)
    #   the key is to know which objects to keep
    #   Keep objects where obj.y < 450
    rembutt = []
    for obj in @fallingObjects
      if obj.y < 450
        rembutt.push obj
    @fallingObjects = rembutt
  # ============================================================
  # This spawns new falling objects - already done for you!
  # ============================================================
  spawnObject: ->
    rand = Math.random()
    x = Math.random() * (@canvas.width - 30)

    if rand < 0.6  # 60% acorns
      @fallingObjects.push
        type: 'acorn'
        x: x
        y: -30
        width: 25
        height: 30
        speed: 2 + @difficulty * 0.5
    else if rand < 0.95  # 35% dust mites
      @fallingObjects.push
        type: 'dustmite'
        x: x
        y: -25
        width: 30
        height: 25
        speed: 2.5 + @difficulty * 0.3
        wobble: 0
    else  # 5% cat bus power-up
      @fallingObjects.push
        type: 'catbus'
        x: x
        y: -35
        width: 50
        height: 30
        speed: 3

  # ============================================================
  # Main update function - calls all your functions!
  # ============================================================
  update: ->
    return if @gameOver

    # Call the functions YOU wrote!
    @moveTotoro()
    @keepTotoroOnScreen()

    # Handle power-up timer (done for you)
    if @totoro.powered
      @totoro.powerTimer--
      if @totoro.powerTimer <= 0
        @totoro.powered = false
        @totoro.speed = @totoro.baseSpeed
        @powerupDisplay.textContent = ''

    # Spawn new objects (done for you)
    @spawnTimer++
    if @spawnTimer >= @spawnInterval
      @spawnObject()
      @spawnTimer = 0

    # Increase difficulty over time (done for you)
    @difficultyTimer++
    if @difficultyTimer >= 200
      @difficulty += 0.2
      @spawnInterval = Math.max(4, @spawnInterval - 3)
      @difficultyTimer = 0

    # Call YOUR function to move objects down!
    @moveFallingObjects()

    # Add wobble to dust mites (done for you)
    for obj in @fallingObjects
      if obj.type is 'dustmite'
        obj.wobble += 0.1
        obj.x += Math.sin(obj.wobble) * 1.5

    # Check collisions using YOUR functions!
    @checkCollisions()

    # Call YOUR function to remove off-screen objects!
    @removeOffScreenObjects()

  checkCollisions: ->
    toRemove = []

    for obj, i in @fallingObjects
      # Use YOUR collides function!
      if @collides(@totoro, obj)
        toRemove.push(i)
        # Use YOUR handleCatch function!
        @handleCatch(obj)

    # Remove collected objects
    for i in toRemove.reverse()
      @fallingObjects.splice(i, 1)

  updateDisplay: ->
    @scoreElement.textContent = @score
    @livesElement.textContent = @lives

  endGame: ->
    @gameOver = true
    @finalScoreElement.textContent = @score
    @gameOverElement.classList.remove('hidden')
    @powerupDisplay.textContent = ''

    # Show leaderboard UI and enable submission
    @submitScoreBtn.disabled = false
    @submitScoreBtn.style.display = 'inline-block'
    @nameInput.disabled = false
    @nameInput.value = @playerName
    @leaderboardStatus.textContent = ''

    # Refresh leaderboard display
    @refreshLeaderboard()

  restart: ->
    @init()
    @gameLoop()

  # ============================================================
  # LootLocker Leaderboard Methods (Simplified)
  # ============================================================

  initLeaderboard: ->
    @lootlocker.init()
    .then => @refreshLeaderboard()
    .catch => @leaderboardList.innerHTML = '<li class="error">Could not connect to leaderboard</li>'

  handleSubmitScore: ->
    return unless @lootlocker.sessionToken

    playerName = @nameInput.value.trim() or 'Anonymous'
    @submitScoreBtn.disabled = true
    @leaderboardStatus.textContent = 'Submitting score...'

    # If player changed their name, start a new session (creates new leaderboard entry)
    nameChanged = @registeredName and playerName isnt @registeredName
    startFresh = if nameChanged then @lootlocker.init() else Promise.resolve()

    startFresh
    .then => @lootlocker.setName(playerName)
    .then => @lootlocker.submitScore(@score)
    .then (result) =>
      # Save the name as their registered name for future submissions
      @registeredName = playerName
      @playerName = playerName
      localStorage.setItem 'playerName', playerName
      @leaderboardStatus.textContent = "Score submitted! Rank: ##{result.rank}"
      @submitScoreBtn.style.display = 'none'
      @nameInput.disabled = true
      @refreshLeaderboard()
    .catch =>
      @leaderboardStatus.textContent = 'Failed to submit score'
      @submitScoreBtn.disabled = false

  refreshLeaderboard: ->
    return unless @lootlocker.sessionToken

    @lootlocker.getScores()
    .then (entries) => @displayLeaderboard(entries)
    .catch => @leaderboardList.innerHTML = '<li class="error">Could not load leaderboard</li>'

  # ============================================================
  # FUNCTION 7: Show the Leaderboard
  # ============================================================
  # This function shows the top scores on the leaderboard!
  #
  # HOW IT WORKS:
  # - 'entries' is a list of score entries from other players
  # - Each entry has:
  #     entry.rank = their position (1 = first place, 2 = second, etc)
  #     entry.player.name = the player's name
  #     entry.score = how many points they got
  # - @addToLeaderboard(rank, name, score) adds one line to the leaderboard
  #
  # WHAT TO DO:
  # - Go through each entry in the list
  # - Get the rank, name, and score from each entry
  # - Call @addToLeaderboard to display it
  #
  # EXAMPLE:
  #   for entry in entries
  #     rank = entry.rank
  #     name = entry.player.name
  #     # now call @addToLeaderboard with rank, name, and score
  # ============================================================
  displayLeaderboard: (entries) ->
    @leaderboardList.innerHTML = ''

    if entries.length is 0
      @leaderboardList.innerHTML = '<li class="no-scores">No scores yet. Be the first!</li>'
      return

    # YOUR CODE HERE
    # Hint: Use "for entry in entries" to loop through all the scores
    # Hint: Get the rank with entry.rank
    # Hint: Get the name with entry.player.name
    # Hint: Get the score with entry.score
    # Hint: Call @addToLeaderboard(rank, name, score) to show each one
    for e in entries
      rank = e.rank
      pn = e.player.name
      score = e.score
      @addToLeaderboard(rank,pn,score)


  # This helper function adds one entry to the leaderboard display
  # (You don't need to change this - just call it from above!)
  addToLeaderboard: (rank, name, score) ->
    li = document.createElement 'li'
    li.className = 'leaderboard-entry'

    rankSpan = document.createElement 'span'
    rankSpan.className = 'rank'
    rankSpan.textContent = "##{rank}"

    nameSpan = document.createElement 'span'
    nameSpan.className = 'player-name'
    nameSpan.textContent = name or 'Anonymous'

    scoreSpan = document.createElement 'span'
    scoreSpan.className = 'player-score'
    scoreSpan.textContent = score

    li.appendChild rankSpan
    li.appendChild nameSpan
    li.appendChild scoreSpan
    @leaderboardList.appendChild li

  # ============================================================
  # All the drawing code below - you don't need to change this!
  # ============================================================
  draw: ->
    # Clear canvas
    @ctx.fillStyle = '#87CEEB'
    @ctx.fillRect(0, 0, @canvas.width, @canvas.height)

    # Draw grass at bottom
    @ctx.fillStyle = '#228B22'
    @ctx.fillRect(0, @canvas.height - 20, @canvas.width, 20)

    # Draw Totoro
    @drawTotoro()

    # Draw falling objects
    for obj in @fallingObjects
      switch obj.type
        when 'acorn' then @drawAcorn(obj)
        when 'dustmite' then @drawDustMite(obj)
        when 'catbus' then @drawCatBus(obj)

  drawTotoro: ->
    x = @totoro.x
    y = @totoro.y

    # Body - gray oval
    @ctx.fillStyle = if @totoro.powered then '#DAA520' else '#696969'
    @ctx.beginPath()
    @ctx.ellipse(x + 40, y + 40, 38, 35, 0, 0, Math.PI * 2)
    @ctx.fill()

    # Belly - lighter gray
    @ctx.fillStyle = '#D3D3D3'
    @ctx.beginPath()
    @ctx.ellipse(x + 40, y + 45, 25, 22, 0, 0, Math.PI * 2)
    @ctx.fill()

    # Belly markings
    @ctx.fillStyle = '#808080'
    for i in [0..5]
      @ctx.beginPath()
      @ctx.ellipse(x + 25 + i * 6, y + 45, 2, 4, 0, 0, Math.PI * 2)
      @ctx.fill()

    # Ears
    @ctx.fillStyle = if @totoro.powered then '#DAA520' else '#696969'
    @ctx.beginPath()
    @ctx.moveTo(x + 15, y + 10)
    @ctx.lineTo(x + 25, y - 5)
    @ctx.lineTo(x + 30, y + 15)
    @ctx.fill()

    @ctx.beginPath()
    @ctx.moveTo(x + 50, y + 15)
    @ctx.lineTo(x + 55, y - 5)
    @ctx.lineTo(x + 65, y + 10)
    @ctx.fill()

    # Eyes
    @ctx.fillStyle = 'white'
    @ctx.beginPath()
    @ctx.arc(x + 30, y + 25, 8, 0, Math.PI * 2)
    @ctx.arc(x + 50, y + 25, 8, 0, Math.PI * 2)
    @ctx.fill()

    # Pupils
    @ctx.fillStyle = 'black'
    @ctx.beginPath()
    @ctx.arc(x + 30, y + 25, 4, 0, Math.PI * 2)
    @ctx.arc(x + 50, y + 25, 4, 0, Math.PI * 2)
    @ctx.fill()

    # Nose
    @ctx.fillStyle = '#2F2F2F'
    @ctx.beginPath()
    @ctx.ellipse(x + 40, y + 32, 5, 3, 0, 0, Math.PI * 2)
    @ctx.fill()

    # Whiskers
    @ctx.strokeStyle = '#2F2F2F'
    @ctx.lineWidth = 1
    for i in [-1, 0, 1]
      @ctx.beginPath()
      @ctx.moveTo(x + 15, y + 35 + i * 4)
      @ctx.lineTo(x + 5, y + 33 + i * 6)
      @ctx.stroke()
      @ctx.beginPath()
      @ctx.moveTo(x + 65, y + 35 + i * 4)
      @ctx.lineTo(x + 75, y + 33 + i * 6)
      @ctx.stroke()

  drawAcorn: (obj) ->
    x = obj.x
    y = obj.y

    # Acorn cap
    @ctx.fillStyle = '#8B4513'
    @ctx.beginPath()
    @ctx.ellipse(x + 12, y + 8, 12, 8, 0, 0, Math.PI * 2)
    @ctx.fill()

    # Cap pattern
    @ctx.strokeStyle = '#654321'
    @ctx.lineWidth = 1
    for i in [0..4]
      @ctx.beginPath()
      @ctx.arc(x + 12, y + 4, 3 + i * 2, 0, Math.PI)
      @ctx.stroke()

    # Stem
    @ctx.fillStyle = '#654321'
    @ctx.fillRect(x + 10, y - 2, 4, 6)

    # Acorn body
    @ctx.fillStyle = '#DEB887'
    @ctx.beginPath()
    @ctx.ellipse(x + 12, y + 20, 10, 12, 0, 0, Math.PI * 2)
    @ctx.fill()

  drawDustMite: (obj) ->
    x = obj.x
    y = obj.y

    # Fuzzy body
    @ctx.fillStyle = '#1a1a1a'
    @ctx.beginPath()
    @ctx.arc(x + 15, y + 12, 12, 0, Math.PI * 2)
    @ctx.fill()

    # Fuzzy edges
    @ctx.fillStyle = '#333333'
    for i in [0..7]
      angle = (i / 8) * Math.PI * 2
      @ctx.beginPath()
      @ctx.arc(
        x + 15 + Math.cos(angle) * 10
        y + 12 + Math.sin(angle) * 10
        4, 0, Math.PI * 2
      )
      @ctx.fill()

    # Eyes
    @ctx.fillStyle = 'white'
    @ctx.beginPath()
    @ctx.arc(x + 11, y + 10, 4, 0, Math.PI * 2)
    @ctx.arc(x + 19, y + 10, 4, 0, Math.PI * 2)
    @ctx.fill()

    # Pupils
    @ctx.fillStyle = 'black'
    @ctx.beginPath()
    @ctx.arc(x + 11, y + 10, 2, 0, Math.PI * 2)
    @ctx.arc(x + 19, y + 10, 2, 0, Math.PI * 2)
    @ctx.fill()

  drawCatBus: (obj) ->
    x = obj.x
    y = obj.y

    # Body
    @ctx.fillStyle = '#DAA520'
    @ctx.beginPath()
    @ctx.roundRect(x, y + 5, 50, 20, 8)
    @ctx.fill()

    # Stripes
    @ctx.fillStyle = '#B8860B'
    for i in [0..3]
      @ctx.fillRect(x + 8 + i * 10, y + 8, 4, 14)

    # Face area
    @ctx.fillStyle = '#DAA520'
    @ctx.beginPath()
    @ctx.arc(x + 45, y + 15, 10, 0, Math.PI * 2)
    @ctx.fill()

    # Eyes
    @ctx.fillStyle = '#FFFF00'
    @ctx.beginPath()
    @ctx.arc(x + 43, y + 12, 4, 0, Math.PI * 2)
    @ctx.arc(x + 50, y + 12, 4, 0, Math.PI * 2)
    @ctx.fill()

    # Pupils
    @ctx.fillStyle = 'black'
    @ctx.beginPath()
    @ctx.arc(x + 43, y + 12, 2, 0, Math.PI * 2)
    @ctx.arc(x + 50, y + 12, 2, 0, Math.PI * 2)
    @ctx.fill()

    # Ears
    @ctx.fillStyle = '#DAA520'
    @ctx.beginPath()
    @ctx.moveTo(x + 40, y + 5)
    @ctx.lineTo(x + 42, y - 3)
    @ctx.lineTo(x + 46, y + 5)
    @ctx.fill()
    @ctx.beginPath()
    @ctx.moveTo(x + 48, y + 5)
    @ctx.lineTo(x + 52, y - 3)
    @ctx.lineTo(x + 54, y + 5)
    @ctx.fill()

    # Legs
    @ctx.fillStyle = '#DAA520'
    for i in [0..3]
      @ctx.fillRect(x + 5 + i * 11, y + 22, 5, 6)

    # Smile
    @ctx.strokeStyle = '#8B4513'
    @ctx.lineWidth = 2
    @ctx.beginPath()
    @ctx.arc(x + 46, y + 16, 5, 0.2, Math.PI - 0.2)
    @ctx.stroke()

  gameLoop: =>
    return if @gameOver
    @update()
    @draw()
    requestAnimationFrame(@gameLoop)

  start: ->
    @gameLoop()

# Start the game when DOM is ready
document.addEventListener 'DOMContentLoaded', ->
  game = new Game()
  game.start()
