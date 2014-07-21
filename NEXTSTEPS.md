NEXT STEPS
----------

[ ] make a shortcut to declare transitions for many from states at once
    addTransition({ from = { "a", "b", "c", to = "d", condition = function () return true end}})

### BUGS ###

The keydrop saga

Two problems:

- running "always" transitions in response to irrelevant keyreleased events
- keys go from "pressed" to "held" in the update, so if we depend on keys being
  not held we run the risk of transitioning out of a state that we should have
  stayed in because another key was pressed before the update set holding to true.

Solutions:

- wrap the x_buster keyreleased call and ensure it is only called when the key
  is "SHOOT".
  - another solution would be to do some additional check in the condition
- set the key to pressed at the beginning of a keypressed event, and to held
  at the end. Set the key to released at the beginning of a keyreleased event
  and to false at the end. This work used to be done in the player update function.

Discussion:

- the first problem is probably still a problem. I solved it with a band-aid around
  the x_buster keyreleased call in player's keyreleased callback. So there might
  be other "always" transitions that will suffer a similar fate.
- the second problem is kind of a special case of the first: there is no way to
  avoid checking for state transitions during irrelevant key events because
  there is no way to know ahead of time what key event will be "irrelevant"
  to a particular state.
- my solution to the second problem is a good one. It is code that I think we
  needed. It does not, however, address the problem in its entirety (in the
  sense mentioned immediately above).


DO THESE FIRST

[ ] When megaman wall jumps in the crook, he gets trapped forever
[ ] When megaman is damaged, he should not be able to wall jump and shoot and charge
[x] megaman should lose charge when damaged
[ ] when megamans hit each other they should both take damage (this failed once)
[x] Megaman loses shots when mashing keys
[x] Megaman loses jumps when mashing keys
[x] Megaman does a little dance when jump and dash are mashed
    - not a bug: when you mash dash and jump you get a little air (like, a pixel)
      and this cause you to fall for one frame when you come out of the dash.
    - we could ensure that the animation for falling doesn't run, but that is
      quite the hefty special case

### Animations ###

[x] resolve the air-dash issues. (Draw a diagram for transitions from dashing)
[x] In megaman X, while in the falling to standing transition, megaman can't jump.
    Any jump presses made during this transition are... DELAYED UNTIL IT IS FINISHED
    - he can jump normally if we skips that animation by landing into a run
    - will not fix
[x] when megaman touches a wall his falling animation should run fast, then he clings
[x] megaman bounces like a gimp when standing at the base of a wall
[x] A second shooting animation plays parallel to some of megaman's animations
[x] switch to and from shooting animation based on the inactive state
[ ] when megaman is climbing and presses away from the wall (but still also pressing towards)
    he should get a little push away (about half his senses distance) (see the game)
[ ] when running and then push the opposite direction but without letting go of the original
    run direction, megaman goes to standing and faces in the original run direction.

### VHS ###

[x] Should store position data, and bark if it gets out of sync
[x] include a command to restart the game
[x] write macros to a file, and then recall them
[x] pressing q should start the recording, and then any other number key should choose
    what macro name to use.
    [x] however, VHS should not record these keypresses: it should only record controller input

[x] add asserts for testing against position data
[x] The recordings all live in a track_list.lua file, and are a table
    of recordings indexed by that number
[x] +/- should change the rate at which game.update gets called, slowing or
    speeding up the game
[x] The game should "re-init" in the start init
[x] VHS should store all the relevant position information, so that we can
    make assertsions about it.
    - padding is still good enough: we only need to make assertions after
      significant updates

[ ] Accept command-line args for playback rate, track file, and track
[ ] the keypress functions needs to be moved into the game_state, as is right
[x] Megaman should die immediately upon falling off the screen

### GOAL ###

The Dead (working title) is a game in which the player takes on the role of
a boss from megaman X, and must defeat megaman... again and again. In this
minimal version we will have:

1. The boss room, with Chill Penguin waiting
2. the door slides up, and megaman enters
3. the battle begins
4. the player can use number keys to activate Chill Penguins abilities,
   and a cool-down will regulate their use
5. megaman will be controlled by an AI that prioritizes shooting at the
   boss and not being hit
6. if megaman loses, he explodes and we go back to step 1
7. if megaman wins, the boss explodes and megaman teleports away

[ ] Entities for the player and boss
[ ] Walls and a floor
[ ] Physics and collision detection/resolution
    - the room should just be a rectangular bounding box
[ ] Movement routines for the boss
    [ ] press 1. to slide across the room and back
    [ ] press 2. to shoot continuously
[ ] to begin with megaman should be player controlled,
    so that we can tweak the physics, jump height etc...
[ ] AI that makes local decisions based on its priorities

[ ] UI with health bars and the numbered abilities and cool-downs
[ ] Music
[ ] Sound effects
[ ] Rad sprites and animations

How To AI
---------

Maybe megaman has priorities: face the boss, maximize distance
to the boss, stand so that shots hit the boss, don't get hit.
At each moment, the buttons that megaman should be holding down
could then be based on these priorities. As bullets get closer,
the priority of holding the jump button increases. When the bullet
is directly below megaman, the priority of jumping goes down, and
the button gets released.

- by default megaman is rapidly pressing the shoot button
- face the enemy
- avoid bullets by jumping over them
- maybe in different states the enemy can count as a bullet (so when
  chill penguin is sliding megaman just treats him like a bullet)
- distance from megaman to the boss should be maximized

[ ] megaman should be able to query the world for the distance to
    the nearest bullet, the position of the boss, and the bosses
    state.
    [ ] The world should have a method like, query(name)
        that returns whatever serialized data that entity exposes. So
        Chill Penguin should expose its position, and state.
    [ ] a method like nearest(name) that returns the position of
        the nearest thing with "name". Maybe name could be "power-up"
        or "bullet".
        - It should also return the bounding box so megaman can
          jump over objects of different sizes

