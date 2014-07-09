NEXT STEPS
----------

### VHS ###

[ ] pressing q should start the recording, and then any other key should choose
    what macro name to use.
[ ] The recordings all live in a recording_macros.lua file, and are a table
    of recordings indexed by that letter. This gets written to disk in the
    stop state
[ ] +/- should change the rate at which game.update gets called, slowing or
    speeding up the game
[ ] @ should send the game into stop state, and then any macro button should
    load the corresponding macro
[ ] The game should "re-init" in the start init

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

