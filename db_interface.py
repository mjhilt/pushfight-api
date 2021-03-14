from utils import hash_pw, check_pw
from tinydb import TinyDB, Query, where

# A generic interface that lets us swap out backends with somewhat more ease

class Base(object):
    def get(self, bucket, key):
        raise NotImplementedError

    def put(self, bucket, value, key='_id'):
        # returns the new/updated doc
        raise NotImplementedError

    def delete(self, bucket, key):
        raise NotImplementedError

    def find(self, bucket, value, key=None):
        raise NotImplementedError

class TestDB(Base):
    # can infer is_setup and current turn from data
    def _board(anchor=None):
        b = {
          "wp1": [0,4],
          "wp2": [1,4],
          "wp3": [3,4],
          "wm1": [2,4],
          "wm2": [2,3],
          "bp1": [0,5],
          "bp2": [2,5],
          "bp3": [3,5],
          "bm1": [2,5],
          "bm2": [1,6],
          "anchor": anchor,
        }
        return b
    def _turn(start_board, moves, end_board):
        return {
            "start_board": start_board,
            "moves": moves,
            "end_board": end_board,
        }

    # Don't use email for your unique ID because then you can't migrate your account to new emails
    USERS = {
        1: {"_id": 1,
            "email": "TeaUponTweed@gmail.com",
            "name": "Parker Dweller",
            "password": hash_pw("salted:hashed_password")
        },
        2: {"_id": 2,
            "email": "mjhilt@gmail.com",
            "name": "Dad-bod",
            "password": '$2b$12$ziwcNkz2FOh3WwBrlbm4P.jDlsFl81alu/Wsj5fyz1u0eM4jaZfky'
        },
        3: {"_id": 3,
            "email": "a",
            "name": "b",
            "password": hash_pw("c")
        },
    }

    GAMES = {
        "no_players_no_moves": {
            "_id":"no_players_no_moves",
            "white_player": None,
            "black_player": None,
            "white_setup": None,
            "black_setup": None,
            "turns": [],
            "game_status": "waiting_for_players",
        },
        "one_player_no_moves_white": {
            "_id":"one_player_no_moves_white",
            "white_player": 1,
            "black_player": None,
            "white_setup": None,
            "black_setup": None,
            "turns": [],
            "game_status": "waiting_for_players",
        },
        "one_player_no_moves_black": {
            "_id":"one_player_no_moves_black",
            "white_player": None,
            "black_player": 1,
            "white_setup": None,
            "black_setup": None,
            "turns": [],
            "game_status": "waiting_for_players",
        },
        "two_players_no_moves": {
            "_id":"two_players_no_moves",
            "white_player": 1,
            "black_player": 2,
            "white_setup": None,
            "black_setup": None,
            "turns": [],
            "game_status": "setup",
        },
        "two_players_one_setup": {
            "_id":"two_players_no_moves",
            "white_player": 1,
            "black_player": 2,
            "white_setup": _board(),
            "black_setup": None,
            "turns": [],
            "game_status": "setup",
        },
        "two_players_with_move": {
            "_id":"two_players_no_moves",
            "white_player": 1,
            "black_player": 2,
            "white_setup": _board(),
            "black_setup": _board(),
            "turns": [_turn(_board(),[],_board([0,4]))],
            "game_status": "ongoing",
        },
    }

    def get(self, bucket, key):
        if bucket == 'users':
            return self.USERS.get(key, {})
        elif bucket == 'games':
            return self.GAMES.get(key, {})
        raise KeyError("No such bucket")

    def put(self, bucket, value, key='_id'):
        try:
            _id = value.get(key)
        except:
            raise ValueError  # or something like that
        # if not isinstance(_id, int):
        #     raise ValueError
        # if not _id == key:
        #     raise ValueError

        if bucket == 'users':
            self.USERS[_id] = value
        elif bucket == 'games':
            self.GAMES[_id] = value
        else:
            raise KeyError("No such bucket")
        return value

    def delete(self, key):
        if not isinstance(key, int):
            raise ValueError
        if bucket == 'users':
            del self.USERS[_id]
        elif bucket == 'games':
            del self.GAMES[_id]
        raise KeyError("No such bucket")

    def find(self, bucket, value, key=None):
        if key is None:
            # Why not do this in the function def?
            # Because then you can't search for "None" as a key
            key = '_id'
        if bucket == 'users':
            return (user for user in self.USERS.values() if (value == user.get(key)))
        elif bucket == 'games':
            return (game for game in self.GAMES.values() if (value == game.get(key)))


class Tiny(Base):
    _DB = TinyDB('db.json')

    @property
    def USERS(self):
        return self._DB.table('USERS')

    @property
    def GAMES(self):
        return self._DB.table('GAMES')

    def get(self, bucket, key):
        if bucket == 'users':
            table = self.USERS
        elif bucket == 'games':
            table = self.GAMES
        else:
            raise KeyError("No such bucket")
        return table.search(where('_id') == key)

    def put(self, bucket, value, key='_id'):
        # We don't need key in this schema, but we might want it in general
        qval = value.get(key)
        if qval is None:
            raise ValueError

        if bucket == 'users':
            table = self.USERS
        elif bucket == 'games':
            table = self.GAMES
        else:
            raise KeyError("No such bucket")

        old = table.get(where(key) == qval)
        _id = value.get('_id')
        if old:
            if _id is not None and _id != old['doc_id']:
                raise ValueError
            table.upsert(value, where('doc_id') == _id)
            doc_id = _id
        else:
            doc_id = table.insert(value)
            def add_id(doc):
                doc['_id'] = doc_id
            table.update(add_id, doc_ids=[doc_id])

        return table.get(doc_id=doc_id)

    def delete(self, key):
        if bucket == 'users':
            table = self.USERS
        elif bucket == 'games':
            table = self.GAMES
        else:
            raise KeyError("No such bucket")
        table.remove(where('_id') == key)

    def find(self, bucket, value, key=None):
        if key is None:
            # Why not do this in the function def?
            # Because then you can't search for "None" as a key
            key = '_id'
        if bucket == 'users':
            table = self.USERS
        elif bucket == 'games':
            table = self.GAMES
        return table.search(where(key) == value)

db = Tiny()