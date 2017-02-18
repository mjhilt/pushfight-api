# pushfight-api
Back-end server code for a push fight game API. This will be a REST API unless I can get around to learning web sockets.


## Endpoints
All endpoints return JSON data unless explicitly noted otherwise.

POST /1/login
  * Login to a specific user account
  * Body: {user: `<uuid>`, password: "secret"}
  * Returns: 200 + a cookie

GET /1/games
  * Get a list of available games to join
  * Returns: {games: [{game: `<uuid>`, opponent: `<uuid>`, name: "death match"}, ...]}

GET /1/game/start?join=`<bool>`&user=`<uuid>`
  * Initialize a new game from an anonymous user
  * Optional query param "join" allows instant joining of any available game
  * Optional query param "user" allows joining as a know user
  * Returns: {game: `<uuid>`, user: `<uuid>`, status: "waiting"|"started", [state: `<boardState>`, color: "white"|"black"]}
  * A cookie is also set if a game is anonymously joined
  * Errors: 404 if game or user is not found, 401 if user is not authenticated

POST /1/game/join
  * Join an available game
  * Body: {game: `<uuid>`, [user: `<uuid>`]}
  * Optional body param "user" allows joining as a know user
  * Returns: {state: `<boardState>`, color: "white"|"black"}
  * Errors: 400 if game is already reserved, 404 if game or user is not found, 401 if user is not authenticated

GET /1/game/status?game=`<uuid>`
  * Check the board state and turn status of a game
  * Returns: {game: `<uuid>`, state: `<boardState>`, turn: "white"|"black"}
  * Errors: 404 if game is not found, 401 if user is not authenticated

POST /1/move
  * Make a move - Returns validation if you won or not
  * Body: {game: `<uuid>`, moves: [state: `<boardState>`,...]}
  * Returns: {win: `<bool>`}
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

