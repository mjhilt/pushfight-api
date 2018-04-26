import bottle as b
# from bottle import route, run, template

games = {}
users = {}

def new_anonymous_user():
    for i in xrange(10000):
        if i not in users:
            users[i] = 'anonymous'
            return i

def start_new_game(user, name=None):
    if name == 'None':
        name = '{} vs. YOU'.format(users[user])
    return Game(user, name)

def get_game_uuid(game):
    for i in xrange(10000):
        if i not in games:
            games[i] = game
            return i

class Game(object):
    def __init__(self, user, name):
        self.id = get_game_uuid(self)
        self.status = 'waiting'
        self.players = [user]
        self.name = name

    def join(self, user):
        self.players.append(user)
        self.status = 'started'
        self.board = init_board()

        # Pick player colors
        # TODO: Make dict keyed by player id
        self.colors = rand.sort([1,2])


@b.post('/1/login')
def login():
    # Body: {user: `<uuid>`, password: "secret"}
    raise NotImplementedError
    body = b.request
    user = body.get('user')
    password = body.get('password')
    if not user or not password:
        b.abort('400', "Bad request")

    is_valid_user = check_cred(user, password)
    if not is_valid_user:
        b.abort('403', "Login not correct")

    cookie = make_cookie(user)
    b.response.set_cookie(cookie)
    b.response.status_code = 204


@b.get('/1/games')
def get_games():
    # Returns: {games: [{game: `<uuid>`, opponent: `<uuid>`, name: "death match"}, ...]}
    game_data = [{
        "game": g.id,
        "opponent": g.players[0],
        "name": g.name
    } for g in games]
    return {"games": game_data}


@b.get('/1/game/start')
def gameStart_1():
    # Query options: join=`<bool>`, user=`<uuid>`
    # Returns: {game: `<uuid>`, user: `<uuid>`, status: "waiting"|"started", [state: `<boardState>`, color: "white"|"black"]}
    print b.request.query

    user = b.request.query.user
    if user:
        # Throw/return error code if bad user
        validate_user()
    else:
        user = new_anonymous_user()

    retval = {}
    game = None
    if b.request.query.join:
        game = find_open_game()
    if game is None:
        game = start_new_game(user)

    retval = {
        "game": game.id,
        "user": user,
        "status": game.status
    }
    if game.status == 'started':
        retval['state'] = game.board
        retval['color'] = game.color[user]

    return retval


@b.post('/1/game/join')
def post_game_join():
    # Body: {game: `<uuid>`, [user: `<uuid>`]}
    # Optional body param "user" allows joining as a know user
    # Returns: {state: `<boardState>`, color: "white"|"black"}
    body = b.request
    gid = body.get('game')
    if not game:
        abort(400, 'Bad request - no game id')
    game = games.get(gid)
    if not game:
        b.abort(404, 'Game {} not found'.format(gid))

    user = body.get('user')
    if user:
        validate_user()
    else:
        user = new_anonymous_user()

    game.join(user)

    return {
        "state": game.state,
        "color": game.color[user],
    }


@b.get('/1/game/status')
def get_game_status():
    gid = b.request.query.game
    game = find_game_by_id(gid)
    if game:
        return game.status
    else:
        b.abort(404, '{} not found'.format(gid))


@b.post('/1/move')
def post_move():
    body = b.request
    raise NotImplementedError


def perform_turn(board, turn)
    # Returns False if its an invalid turn
    newboard = board.copy()
    for move in turn[:-1]
        if is_valid_move(newboard,move):
            perform_move(newboard,move)
        else:
            return False

    push = turn[-1]
    if is_valid_push(newboard,push):
         perform_push(newboard,push)
     else:
        return False

    return newboard


def is_valid_push(board, push):
    is_valid = move[1] in board.values() 
    return is_valid

def is_valid_move(board, move):
    #Needs more refinement
    is_valid = move[1] not in board.values() 
    return is_valid

def perform_move(board, move):
    board[move[0]]=move[1]


def perform_push(board, move):





b.run(host='localhost', port=8080)