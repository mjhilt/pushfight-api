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

session_key = None

def init_board():
    return EXAMPLE_BOARD


def check_cred(user, password):
    # Check a user's stored password against a presented one
    for rec in db.find('users', user, key='email'):
        stored = rec.get('password').encode('utf8')
        return stored and check_pw(password, stored)
    for rec in db.find('users', user, key='username'):
        stored = rec.get('password').encode('utf8')
        return stored and check_pw(password, stored)
    return False


def _auth_check(user, token):
    try:
        b = session_key.decrypt(bytes(token, 'utf8'))
    except InvalidToken:
        print('AUTH: InvalidToken', file=sys.stderr)
        return False
    try:
        info = json.loads(str(b, 'utf8'))
    except:
        print('AUTH: Failed to load info', file=sys.stderr)
        return False
    print(user)
    check = user == info.get('user')
    if not check:
        print('AUTH: Failed to pass check', file=sys.stderr)
    return check


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
    username = body.get('username')
    password = body.get('password')
    if not all([username,email,password]):
        print("Bad request - no username/email/password", file=sys.stderr)
        b.abort(400, "Bad request - no username/email/password")

    current = db.find('users', email, key='email')
    if len(current) > 0:
        print("Email already registered", file=sys.stderr)
        b.abort(400, "Email already registered")

    current = db.find('users', username, key='username')
    if len(current) > 0:
        print("Username already taken", file=sys.stderr)
        b.abort(400, "Username already taken")

    hashed_string = hash_pw(password)
    doc = db.put('users', {"email": email, "password": hashed_string, "username": username}, key='username')

    # now = time.time()
    token_info = {
        "user": username,
        # "expires": now + 3600,
    }
    token_bytes = session_key.encrypt(bytes(json.dumps(token_info), 'utf8'))
    return {"username": username, "token": str(token_bytes, 'utf8')}


@b.post('/1/login')
def login():
    # Body: {user: `<uuid>`, toket: "newsecret"}
    body = b.request.json
    if not body:
        b.abort(400, "Bad request")

    user = None
    for rec in db.find('users', body.get('user'), key='email'):
        user = rec['username']
        break
    if user is None:
        for rec in db.find('users', body.get('user'), key='username'):
            user = rec['username']
            break


    password = body.get('password')
    if not user or not password:
        print("Bad login request", file=sys.stderr)
        b.abort(400, "Bad request")

    is_valid_user = check_cred(user, base64.b64decode(bytes(password, 'utf8')))
    if not is_valid_user:
        b.abort(403, "Login not correct")

    # now = time.time()
    token_info = {
        "user": user,
        # "expires": now + 3600,
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
@b.auth_basic(_auth_check)
def get_open_games():
    # Returns: {games: [{game: `<uuid>`, opponent: `<uuid>`}, ...]}
    user,_ = b.request.auth
    games = []
    for g in db.find("games", "waitingforplayers", key="gameStage"):
        wp = g["white_player"]
        bp = g["black_player"]
        if user in (wp,bp):
            continue

        games.append({
            "game": g["_id"],
            "opponent": wp if wp else bp
        })
    # TODO: should limit the number of returned results more intelligently
    random.shuffle(games)
    return {"games": games[:10]}


def _gen_my_games(user):
    for key in ("white", "black"):
        for g in db.find("games", user, key=key + "_player"):
            yield key, g

@b.get('/1/mygames')
@b.auth_basic(_auth_check)
def get_my_games():
    # Returns: {games: [{game: `<uuid>`, opponent: `<uuid>`}, ...]}
    user,_ = b.request.auth
    games = []
    for color, g in _gen_my_games(user):
        # don't show unstarted games
        if _get_game_stage(g) == 'waitingforplayers':
            continue
        # don't show completed games
        if g['game_over'] is not None:
            continue
        if color == 'white_player':
            opponent = g['black_player']
        else:
            opponent = g['white_player']

        games.append({
            "game": g["_id"],
            "opponent": opponent,
        })

    return {"games": games}

def make_game(user1, user2, color='white', timed=False):
    _id = '{}_{}_{}'.format(user1, user2, int(time.time()))
    turn = {
        'moves': [],
        'gameStage': 'whitesetup' if user2 is not None else 'waitingforplayers',
        'board': init_board(),
        'turn_number': 1,
    }
    return {
            "_id": _id,
            "white_player": user1 if color == 'white' else user2,
            "black_player": user2 if color == 'white' else user1,
            "turns": [turn],
            "game_over": None,
            'gameStage': turn['gameStage'],
            'request': "no_request"
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
       return start_impl(opponent=rec['username'])

    b.abort(404, "No such opponent")


@b.post('/1/game/start')
@b.auth_basic(_auth_check)
def post_start():
    return start_impl()


def start_impl(opponent=None):
    body = b.request
    username,_ = b.request.auth

    if "color" not in body or body.color not in ["white", "black"]:
        color = random.choice(["white", "black"])
    else:
        color = body.color

    try:
        timed = body.timed
    except AttributeError:
        timed = False

    game = make_game(username, opponent, color=color, timed=timed)
    db.put('games', game)
    return {
        "game": game['_id'],
        "board": game['turns'][-1]['board'],
        "gameStage": game['turns'][-1]['gameStage'],
        "request": game['request'],
        "color": color,
        "moves": game['turns'][-1]['moves']
        # "timer": None, # TODO
    }

def _log_abort(code, msg):
    print(msg, file=sys.stderr)
    b.abort(code, msg)

@b.post('/1/game/join')
@b.auth_basic(_auth_check)
def post_game_join():
    '''
    returns {game:game_id}
    '''
    user,_ = b.request.auth
    body = b.request.json
    # print('post_game_join', body)
    gid = body.get('game')
    games = db.get('games', gid)
    if len(games)==0:
        return _log_abort(404, 'Game {} not found'.format(gid))

    game = games[0]
    if game['white_player'] is None:
        game['white_player'] = user
    elif game['black_player'] is None:
        game['black_player'] = user
    else:
        return _log_abort(404, 'Game {} already started'.format(gid))
    # game['gameOver'] = None
    # game['']
    # game['gameStage'] = 'whitesetup'
    game['turns'][-1]['gameStage'] = 'whitesetup'

    db.put('games', game)

    # game
    return {
        "game": game['_id'],
    }

def _get_game_info(game_id, user):
    '''
    helper to determine get game from db
    returns (game, user color {black, white})
    '''
    games = db.find('games', game_id)
    if len(games) == 0:
        raise ValueError("No such game")
    assert len(games) == 1
    game = games[0]
    # if user not in [game['white_player'], game['black_player']]:
    if user == game['white_player']:
        color = 'white'
    elif user == game['black_player']:
        color = 'black'
    else:
        raise ValueError("User not associated with game")
    return game, color

def _get_game_stage(game):
    '''
    helper to parse game object and return definitive game stage
    TODO having gameStage within the turn and twice on top feels *horrible*
    '''
    # if 'game_over' in game and game['game_over'] is not None:
    if game['game_over'] is not None:
        return game['game_over']
    else:
        return game['turns'][-1]['gameStage']

def _game_info(game, color):
    '''
    Helper to format game + color into GameInfo return
    '''
    return {
        "game": game['_id'],
        "board": game['turns'][-1]['board'],
        "moves": game['turns'][-1]['moves'],
        "gameStage": _get_game_stage(game),
        "request": game['request'],
        "color": color,
        "turn": game['turns'][-1]['turn_number'],
    }

@b.post('/1/move')
@b.auth_basic(_auth_check)
def post_move():
    '''
    Record a move.
    Returns GameInfo (defined in Api.elm)
    '''
    body = b.request.json
    user,_ = b.request.auth
    game_id = body['game']
    turn_number = body['turn']
    print('moving', turn_number)
    try:
        game, color = _get_game_info(game_id, user)
    except ValueError as e:
        print(e, file=sys.stderr)
        _log_abort(404, "User not associated with game")
        return
    else:
        # assert :
        if turn_number != game['turns'][-1]['turn_number']:
            _log_abort(404, "Turn out of order")
            return

        turn = {
            'moves': body['moves'],
            'gameStage': body['startGameStage'],
            'board': body['startBoard'],
            'moves': body['moves'],
            'turn_number': turn_number,
        }
        # print(turn)
        game['turns'][-1] = turn
        if body['final']:
            next_turn = {
                'moves': [],
                'gameStage': body['finalGameStage'],
                'board': body['finalBoard'],
                'moves': [],
                'turn_number': turn_number + 1
            }
            game['gameStage'] = next_turn['gameStage']
            game['turns'].append(next_turn)
            if body['finalGameStage'] in ('whitewon', 'blackwon', 'draw'):
                game['game_over'] = body['finalGameStage']


        # if game['turns'][-1]['board'] != body['startBoard']:
        #     return _log_abort(404, "Move not valid")

        # if body['json']['final']:
        #     if game['turns'][-1]['board'] == body['startBoard']:
        #         game['turns'].append(turn)
        #     elif game['turns'][-2]['board'] == body['startBoard']:
        #         game['turns'][-1] = turn
        #     else:
        #         _log_abort(404, "Move not valid")
        # else:

        # if game['turns'][-1]['board'] == body['startBoard']:
        #     game['turns'].append(turn)
        # elif game['turns'][-2]['board'] == body['startBoard']:
        #     game['turns'][-1] = turn
        # else:
        #     _log_abort(404, "Move not valid")
        db.put('games', game)
        return _game_info(game, color)
        # else:
            # b.abort(404, "Move not valid")
            # return

@b.post('/1/update')
@b.auth_basic(_auth_check)
def post_update():
    '''
    handles requests (draw, takebacks), game status, & resignations
    returns GameInfo (defined in Api.elm)
    '''
    body = b.request
    user,_ = b.request.auth
    game_id = body.json['game']
    try:
        game, color = _get_game_info(game_id, user)
    except  ValueError as e:
        print(e, file=sys.stderr)
        b.abort(404, str(e))
        return
    else:

        if game['game_over'] is None:
            print('Not applying update. Game over',file=sys.stderr)
            if 'takeback_requested_white' in body.json:
                game['request'] = 'takeback_requested_white'
            if 'takeback_requested_black' in body.json:
                game['request'] = 'takeback_requested_black'
            if 'draw_offered_white' in body.json:
                game['request'] = 'draw_offered_white'
            if 'draw_offered_black' in body.json:
                game['request'] = 'draw_offered_black'
            if 'accept_takeback' in body.json:
                if len(game['turns']) > 1:
                    game['turns'] = game['turns'][:-1]
                    game['gameStage'] = game['turns'][-1]['gameStage']
                    game['turns'][-1]['moves'] = []
                game['request'] = "no_request"
            if 'clear_request' in body.json:
                game['request'] = 'no_request'

            if 'resign' in body.json:
                if color == 'white':
                    game['game_over'] = 'blackwon'
                else:
                    game['game_over'] = 'whitewon'
                game['request'] = "no_request"

            if 'accept_draw' in body.json:
                game['game_over'] = 'draw'
                game['request'] = "no_request"

            db.put('games', game)

        return _game_info(game, color)

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
