import os
import sys
import random
import base64
import time
import json
from cryptography.fernet import Fernet, InvalidToken

import bottle as b
# from bottle import route, run, template

from pushfight import EXAMPLE_BOARD
from db_interface import db
from utils import hash_pw, check_pw

games = {}
users = {}
session_key = None

def init_board():
    return EXAMPLE_BOARD


def check_cred(user, password):
    # Check a user's stored password against a presented one
    for rec in db.find('users', user, key='email'):
        stored = rec.get('password').encode('utf8')
        return stored and check_pw(password, stored)
    return False


def _auth_check(user, token):
    try:
        b = session_key.decrypt(bytes(token, 'utf8'))
    except InvalidToken:
        return False
    try:
        info = json.loads(str(b, 'utf8'))
    except:
        return False
    return user == info.get('user')

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


# def find_game_by_id(gid):
    # print(games)
    # return games[gid]

# class Game(object):
#     def __init__(self, user, name):
#         self.id = get_game_uuid(self)
#         self.status = 'waiting'
#         self.players = [user]
#         self.name = name

#     def join(self, user):
#         self.players.append(user)
#         self.status = 'started'
#         self.board = init_board()

#         # Pick player colors
#         # TODO: Make dict keyed by player id
#         self.colors = random.shuffle([1,2])

@b.post('/1/register')
def register():
    # Body: {email: "a.valid.email@domain.com", password: "secret"}
    #   * Returns: {username: `<uuid>`, token: "newsecret"}
    body = b.request.json
    if not body:
        b.abort(400, "Bad request - no body")
    if 'user' in body:
        body = body['user']
    email = body.get('email')
    password = body.get('password')
    if not email or not password:
        b.abort(400, "Bad request - no username/password")

    current = db.find('users', email, key='email')
    if len(current) > 0:
        b.abort(400, "Email already registered")
    hashed_string = hash_pw(password)
    doc = db.put('users', {"email": email, "password": hashed_string}, key='email')
    return {"username": doc['_id']}


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

    now = time.time()
    token_info = {
        "user": user,
        "expires": now + 3600,
    }
    token_bytes = session_key.encrypt(bytes(json.dumps(token_info), 'utf8'))
    return {"username": user, "token": str(token_bytes, 'utf8')}


@b.post('/1/checkuser')
@b.auth_basic(_auth_check)
def check_user():
    user,_ = b.request.auth
    if user:
        return b.Response(user)
    else:
        b.abort(401, "Bad auth")


@b.get('/1/opengames')
def get_open_games():
    # Returns: {games: [{game: `<uuid>`, opponent: `<uuid>`}, ...]}
    game_data = []
    # TODO: should limit the number of returned results
    for g in db.find("games", "waitingforplayers", key="game_status"):
        opponent = g["white_player"]
        game_data.append({
            "game": g["_id"],
            "opponent": opponent if opponent else g["black_player"],
        })
    return {"games": game_data}


@b.get('/1/mygames')
@b.auth_basic(_auth_check)
def get_my_games():
    # Returns: {games: [`<uuid>`, ...]}
    user,_ = b.request.auth
    games = []
    for key in ("white_player", "black_player"):
        games += [g["_id"] for g in db.find("games", user, key=key)]
    return {"games": games}

# def _getLatestState(game):
#     if len(game.turns) == 0:
#         return make_game()
#     else:
#         return game.turns[-1]['endBoard']
    # if game['black_setup'] is None:
    #     if game['white_setup'] is None:
    #         state = make_game()
    #     else:
    #         state = game['white_setup']
    # else:
    #     if len(game['turns'] == 0):
    #         state = game['black_setup']
    #     else:
    #         state = game['turns'][-1]['finalBoard']

    # return state

# @b.post('/1/game/status/<game_id>')
@b.get('/1/game/status')
@b.auth_basic(_auth_check)
def game_status():
# def game_status(game_id):
    # print('ere')
    user,_ = b.request.auth
    # body = b.request.json
    # print(user)
    # print(b.request.json)
    # body = b.request.body.read()
    # print(body)
    # print('ere')
    # game_id = body.game
    # game_id = b.request.query['game']
    # for k,v in b.request.query.items():
    #     print(k,v)
    game_id = b.request.query.game
    # print(game_id)
    # print('#############')
    games = db.find('games', game_id)
    # print(games)
    if len(games) == 0:
        b.abort(404, "No such game")
        return
    assert len(games) == 1
    game = games[0]
    if user not in [game['white_player'], game['black_player']]:
        b.abort(404, "User not associated with game")
        return

    color = 'white' if user == game['white_player'] else 'black'
    latest = game['turns'][-1]
    print('^^^^^', latest)
    ret = {
        "game": game['_id'],
        'board': latest['board'],
        'gameStage': latest['gameStage'],
        'request': game['request'],
        'color': color,
    }
    # ret = {
    #     'board': _getLatestState(game),
    #     'gameStage': game['gameStage'],
    #     'color': color,
    #     'request': game['request'],
    # }
    return ret

def make_game(user1, user2, color='white', timed=False):
    _id = '{}_{}_{}'.format(user1, user2, int(time.time()))
    turn = {
        # 'startBoard': None,
        # 'startGameStage': None,
        'moves': [],
        'gameStage': 'whitesetup' if user2 is not None else 'waitingforplayers',
        'board': init_board(),
    }
    return {
            "_id": _id,
            # "state": init_board(),
            "white_player": user1 if color == 'white' else user2,
            "black_player": user2 if color == 'white' else user1,
            # "white_setup": None,
            # "black_setup": None,
            "turns": [turn],
            # 'color': color,
            # "game_stage": "WhiteSetup",
            'request': "NoRequest"
        }


# This whole API endpoint feels cringy if this were anything more than a group of friends' server
@b.post('/1/game/challenge')
@b.auth_basic(_auth_check)
def post_challenge():
    body = b.request.json
    opponent_email = body.get('opponent')
    if opponent_email is None:
        b.abort(400, "Opponent not provided")
        return

    for rec in db.find('users', opponent_email, key='email'):
       return start_impl(opponent=opponent_email)

    b.abort(404, "No such opponent")


@b.post('/1/game/start')
@b.auth_basic(_auth_check)
def post_start():
    return start_impl()


def start_impl(opponent=None):
    body = b.request
    # username = body.user
    username,_ = b.request.auth
    # if username != b.request.get_cookie("user", secret=session_key):
        # b.abort(401, "Bad cookie")

    # TODO: This is really dumb that we look up the user to check the cookie
    #       but then look it up again here. We should fix that.
    # user = None
    # for rec in db.find('users', username, key='email'):
    #     user = rec
    #     break
    # if user is None:
    #     print("Failed to find user")
    #     b.abort(404, "Failed to find user")
    #     return
    # color = body.color
    if "color" not in body or body.color not in ["white", "black"]:
        color = random.choice(["white", "black"])
    else:
        color = body.color
    # print('wakka', color)
    # if color not in
    # try:
    #     color = body.color
    # except KeyError:
    #     color = 'white'

    try:
        timed = body.timed
    except AttributeError:
        timed = False

    game = make_game(username, opponent, color=color, timed=timed)
    print(game)
    db.put('games', game)
    return {
        "game": game['_id'],
        "board": game['turns'][-1]['board'],
        "gameStage": game['turns'][-1]['gameStage'],
        "request": game['request'],
        "color": color,
        # "timer": None, # TODO
    }

# def find_open_game():
#     for gid, game in games.items():
#         if len(game.players) == 1:
#             return gid, game
#     return None, None

# @b.get('/1/game/start')
# def gameStart_1():
#     # Query options: join=`<bool>`, user=`<uuid>`
#     # Returns: {game: `<uuid>`, user: `<uuid>`, status: "waiting"|"started", [state: `<boardState>`, color: "white"|"black"]}
#     print(b.request.query)

#     user = b.request.query.user
#     if user:
#         if user != b.request.get_cookie("user", secret=session_key):
#             b.abort(401, "Bad cookie")
#     else:
#         user = new_anonymous_user()

#     retval = {}
#     game = None
#     if b.request.query.join:
#         _, game = find_open_game()

#     if game is None:
#         game = start_new_game(user)

#     retval = {
#         "game": game.id,
#         "user": user,
#         # "status": game.status,
#         'color': game.color[user],
#     }
#     # db.out
#     # if game.status != 'waitingforplayers':
#     #     retval['state'] = game.board
#     #     retval['color'] = game.color[user]

#     return retval


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
        "game": game['_id'],
        "state": game.state,
        "color": game.color[user],
        "timer": None, # TODO
    }


# @b.get('/1/game/status')
# def get_game_status():
#     gid = b.request.query.game
#     game = db.find('games', gid)
#     if game:
#         # return game.status
#     else:
#         b.abort(404, '{} not found'.format(gid))


@b.post('/1/move')
def post_move():
    body = b.request
    user,_ = b.request.auth
    game_id = body.gameId
    games = db.find('games', game_id, key='email')
    if len(games) == 0:
        b.abort(404, "No such game")
        return
    assert len(games) == 1
    game = games[0]
    if user not in [game['white_player'], game['black_player']]:
        b.abort(404, "User not associated with game")
        return
    # if body.startGameStage == 'WhiteSetup':
    #     game['white_setup'] = body.endBoard
    # elif body.startGameStage == 'BlackSetup':
    #     game['white_setup'] = body.endBoard
    # board = board.board
    turn = {
        # 'startBoard': body.startBoard,
        # 'startGameStage': body.startGameStage,
        'moves': body.moves,
        'gameStage': body.endGameStage,
        'board': body.endBoard,
    }
    # if len(game.turns) == 0:
        # game['turns'].append(turn)
    if game['turns'][-1]['board'] == body.startBoard:
        game['turns'].append(turn)
        db.put('games', game)
        return {
            "game": game['_id'],
            "board": game['turns'][-1]['board'],
            "gameStage": game['turns'][-1]['gameStage'],
            "request": game['request'],
            "color": color,
        }
    else:
        b.abort(404, "Move does not match")
        return

DIRNAME = os.path.dirname(os.path.realpath(__file__))

@b.route('/<filepath:path>')
def server_static(filepath):
    return b.static_file(filepath, root=os.path.join(DIRNAME, 'deploy/'))

@b.route('/')
def server_static(filepath="index.html"):
    return b.static_file(filepath, root=os.path.join(DIRNAME, 'deploy/'))


def load_session_key(filename='secret_api_key'):
    global session_key
    with open(filename,'rb') as f:
        session_key = Fernet(f.read())


if __name__ == '__main__':
    if not os.path.exists('secret_api_key'):
        print('Generating a new api key')
        key = Fernet.generate_key()
        with open('secret_api_key','wb') as f:
            f.write(key)

    load_session_key()
    b.run(host='localhost', port=8080)
