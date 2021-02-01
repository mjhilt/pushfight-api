import sys
import random
import bcrypt

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
    return bcrypt.hashpw(plaintext, bcrypt.gensalt())

def check_pw(pw, hashed):
    return bcrypt.checkpw(pw, hashed)


# These are just more generic names for doing the bcrypt based stuff
def sign_string(string):
    return hash_pw(session_key+string)

def validate_string(string, hashed):
    return check_pw(session_key+string, hashed)


def check_cred(user, password):
    # Check a user's stored password against a presented one
    for rec in db.find('users', user, key='email'):
        stored = reg.get('password')
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
    # Body: {user: `<uuid>`, password: "secret"} - base64 encoded though
    body = b.request
    user = body.get('user')
    password = body.get('password')
    if not user or not password:
        b.abort('400', "Bad request")

    is_valid_user = check_cred(user, password)
    if not is_valid_user:
        b.abort('403', "Login not correct")

    b.response.set_cookie("user", user)
    b.response.set_cookie("auth", sign_string(user))
    b.response.status_code = 204


@b.get('/1/games')
def get_games():
    # Returns: {games: [{game: `<uuid>`, opponent: `<uuid>`, name: "death match"}, ...]}
    game_data = [{
        "game": g.id,
        # "opponent": g.players[0],
        "players": ",".join(g.players),
        "name": g.name
    } for g in games]
    return {"games": game_data}

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
        if not validate_string(user, request.get_cookie("auth")):
            b.abort('401', "Bad cookie")
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
        if not validate_string(user, request.get_cookie("auth")):
            b.abort('401', "Bad cookie")
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
