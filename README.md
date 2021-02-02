# pushfight-api
Back-end server code for a push fight game API. This will be a REST API unless I can get around to learning web sockets.


## Endpoints
All endpoints return JSON data unless explicitly noted otherwise.

POST /1/login
  * Login to a specific user account
  * Body: {user: `<uuid>`, password: "secret"}
  * Returns: 200 + a cookie

GET /1/opengames
  * Get a list of available games to join
  * Returns: {games: [{game: `<uuid>`, opponent: `<uuid>`}, ...]}

GET /1/mygames?user=`<uuid>`
  * Get a list of games where you, "user" is a player
  * Required query param "user"
  * Returns: {games: [{game: `<uuid>`}, ...]}

POST /1/game/challenge
  * Challenge a specific user to a new game
  * Body: {user: `<uuid>`, opponent:`<uuid>`, color:`<color>`, timed:`<bool>`}
  * timed == true indicates that this is a timed game
  * Optional body param "color"("white"|"black") specifies which color user will play in game. Otherwise a random color is chosen
  * Returns: {game: `<uuid>`, state: `<boardState>`, color: "white"|"black", timer:`<timeStatus>`}
  * Errors: 404 if either user is not found, 401 if user is not authenticated

POST /1/game/start
  * Initialize a new game
  * Body: {user: `<uuid>`, color:`<color>`, timed:`<bool>`}
  * timed == true indicates that this is a timed game
  * Optional body param "color"("white"|"black") specifies which color user will play in game. Otherwise a random color is chosen
  * Returns: {game: `<uuid>`, state: `<boardState>`, color: "white"|"black", timer:`<timeStatus>`}
  * Errors: 404 if user is not found, 401 if user is not authenticated

POST /1/game/join
  * Join an available game
  * Body: {game: `<uuid>`, user: `<uuid>`}
  * Returns: {state: `<boardState>`, color: "white"|"black", timer:`<timeStatus>`}
  * Errors: 400 if game is already reserved, 404 if game or user is not found, 401 if user is not authenticated

GET /1/game/status?game=`<uuid>`
  * Check the board state and turn status of a game
  * Returns: {game: `<uuid>`, state: `<boardState>`, turn: "white"|"black", gameStage:"setup"|"ongoing"|"whiteWon"|"blackWon"|"draw", timer:`<timeStatus>`}
  * Errors: 404 if game is not found, 401 if user is not authenticated

POST /1/move
  * Make a move - Returns validation if you won or not
  * Body: {game: `<uuid>`, user: `<uuid>`, startBoard: `<boardState>`, moves: [`<move>`], endBoard: `<boardState>`, timer:`<timeStatus>`}
  * Returns: {moveAccepted: `<bool>`, gameStage:"setup"|"ongoing"|"over"}
  * Errors: 400 if move is not valid, 401 if user is not authenticated, 403 if it is not your turn


## Board State
The push fight board is represented as the position of the 11 pieces on a sparse 4x10 matrix. The matrix is zero indexed, and some of the positions are not valid for pieces. These are (0,0), (3,0), (0,9) and (3,9).

Due to the asymmetric nature of the board, there are two possible configuration to choose from for whether or not (0,2) is a "on board" or "off board" position. We will choose it to be an "off board" position for our purposes. This implies that (3,7) is also "off board", while (0,7) and (3,2) are "on board" positions.

Row/Column | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
-----------|---|---|---|---|---|---|---|---|---|---| 
**0**|:no_entry_sign:|:checkered_flag:|:checkered_flag:|:black_large_square:|:black_large_square:|:black_large_square:|:black_large_square:|:black_large_square:|:checkered_flag:|:no_entry_sign:|
**1**|:checkered_flag:|:black_large_square:|:black_large_square:|:black_large_square:|:black_large_square:|:black_large_square:|:black_large_square:|:black_large_square:|:black_large_square:|:checkered_flag:|
**2**|:checkered_flag:|:black_large_square:|:black_large_square:|:black_large_square:|:black_large_square:|:black_large_square:|:black_large_square:|:black_large_square:|:black_large_square:|:checkered_flag:|
**3**|:no_entry_sign:|:checkered_flag:|:black_large_square:|:black_large_square:|:black_large_square:|:black_large_square:|:black_large_square:|:checkered_flag:|:checkered_flag:|:no_entry_sign:|

The actual representation of the board state will be with a nested JSON object. There will be 11 keys in the object, each naming one of the 11 pieces. Ten of the piece names will be composed of the color, type, and a number, as given below; the final piece will be called "anchor".

 Color | Type   | Board State Names
-------|--------|------------------
 White | Pusher | wp1, wp2, wp3
 Black | Mover  | bm1, bm2

An example of a valid starting board state object is then given by:
```
{
  wp1: [0,4],
  wp2: [1,4],
  wp3: [3,4],
  wm1: [2,4],
  wm2: [2,3],
  bp1: [0,5],
  bp2: [2,5],
  bp3: [3,5],
  bm1: [2,5],
  bm2: [1,6],
  anchor: None,
}
```

A move is just a list of 1,2,or 3 from/to pairs. A valid move would be
```
[
  {from: [0,4], to: [0,5]},
  {from: [2,3], to: [3,3]},
]
```

A time status is either `null` or
{
  "white_time_remaining": `<int>`,
  "black_time_remaining": `<int>`,
  "additional_time_per_turn": `<int>`
}
