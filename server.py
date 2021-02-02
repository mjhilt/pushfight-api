import sys
import random
import bcrypt
import base64

import bottle as b
# from bottle import route, run, template

from pushfight import EXAMPLE_BOARD
from db_interface import db

games = {}
users = {}
session_key = 'a super secret string we should read from some file'

def init_board():
    return EXAMPLE_BOARD


# We use bcrypt to do the actual hashing and comparisons
def hash_pw(plaintext):
    return bcrypt.hashpw(plaintext.encode(), bcrypt.gensalt())

def check_pw(pw, hashed):
    return bcrypt.checkpw(pw, hashed)

def check_cred(user, password):
    # Check a user's stored password against a presented one
    for rec in db.find('users', user, key='email'):
        stored = rec.get('password')
        return stored and check_pw(password, stored)
    return False


def new_anonymous_user():
    for i in range(10000):
        if i not in users:
            users[i] = 'anonymous'
            return i


def start_new_game(user, name=None):
    if name == 'None':
        name = '{} vs. YOU'.format(users[user])
    return Game(user, name)


def get_game_uuid(game):
    for i in range(10000):
        if i not in games:
            games[i] = game
            return i
    print('No slots available! Panic!', file=sys.stderr)


def find_game_by_id(gid):
    return games[gid]


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
        self.colors = random.shuffle([1,2])


@b.post('/1/login')
def login():
    # Body: {user: `<uuid>`, password: <base64 encoded password>}
    body = b.request.json
    if not body:
        b.abort(400, "Bad request")
    user = body.get('user')
    password = body.get('password')
    if not user or not password:
        b.abort(400, "Bad request")

    is_valid_user = check_cred(user, base64.b64decode(bytes(password, 'utf8')))
    if not is_valid_user:
        b.abort(403, "Login not correct")

    b.response.set_cookie("user", user, secret=session_key)
    return


@b.post('/1/checkuser')
def check_user():
    # Testing endpoint for the cookie
    user = b.request.get_cookie("user", secret=session_key)
    if user:
        return b.Response(user)
    else:
        b.abort(401, "Bad cookie")


@b.get('/1/opengames')
def get_games():
    # Returns: {games: [{game: `<uuid>`, opponent: `<uuid>`}, ...]}
    game_data = []
    # TODO: should limit the number of returned results
    for g in db.find("games", "waiting_for_players", key="game_status"):
        opponent = g["white_player"]
        game_data.append({
            "game": g["_id"],
            "opponent": opponent if opponent else g["black_player"],
        })
    return {"games": game_data}


@b.get('/1/mygames')
def get_games():
    # Returns: {games: [`<uuid>`, ...]}
    user = request.query.user
    if user != b.request.get_cookie("user", secret=session_key):
        b.abort(401, "Bad cookie")

    games = []
    for key in ("white_player", "black_player"):
        games += [g["_id"] for g in db.find("games", user, key=key)]
    return {"games": games}


def find_open_game():
    for gid, game in games.items():
        if len(game.players) == 1:
            return gid, game
    return None, None

@b.get('/1/game/start')
def gameStart_1():
    # Query options: join=`<bool>`, user=`<uuid>`
    # Returns: {game: `<uuid>`, user: `<uuid>`, status: "waiting"|"started", [state: `<boardState>`, color: "white"|"black"]}
    print(b.request.query)

    user = b.request.query.user
    if user:
        if user != b.request.get_cookie("user", secret=session_key):
            b.abort(401, "Bad cookie")
    else:
        user = new_anonymous_user()

    retval = {}
    game = None
    if b.request.query.join:
        _, game = find_open_game()

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
    game = games.get(gid)
    if not game:
        b.abort(400, 'Bad request - no game id')
    if not game:
        b.abort(404, 'Game {} not found'.format(gid))

    user = body.get('user')
    if user:
        if user != b.request.get_cookie("user", secret=session_key):
            b.abort(401, "Bad cookie")
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


b.run(host='localhost', port=8080)
