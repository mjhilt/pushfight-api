# A generic interface that lets us swap out backends with somewhat more ease

class Base(object):
    def get(self, bucket, key):
        raise NotImplementedError

    def put(self, bucket, key, value):
        raise NotImplementedError

    def delete(self, bucket, key):
        raise NotImplementedError

    def find(self, bucket, value, key=None):
        raise NotImplementedError


class TestDB(Base):
    # Don't use email for your unique ID because then you can't migrate your account to new emails
    USERS = {
        1: {"_id": 1,
            "email": "TeaUponTweed@gmail.com",
            "name": "Parker Dweller",
            "password": "salted:hashed_password"
        },
        2: {"_id": 2,
            "email": "mjhilt@gmail.com",
            "name": "Dad-bod",
            "password": b'$2b$12$ziwcNkz2FOh3WwBrlbm4P.jDlsFl81alu/Wsj5fyz1u0eM4jaZfky'
        },
    }

    GAMES = {
    }

    def get(self, bucket, key):
        if bucket == 'users':
            return self.USERS.get(key, {})
        elif bucket == 'games':
            return self.GAMES.get(key, {})
        raise KeyError  # No such bucket

    def put(self, bucket, key, value):
        # We don't need key in this schema, but we might want it in general
        try:
            _id = value.get('_id')
        except:
            raise ValueError  # or something like that
        if not isinstance(_id, int):
            raise ValueError
        if not _id == key:
            raise ValueError

        if bucket == 'users':
            self.USERS[_id] = value
        elif bucket == 'games':
            self.GAMES[_id] = value
        raise KeyError  # No such bucket

    def delete(self, key):
        if not isinstance(key, int):
            raise ValueError
        if bucket == 'users':
            del self.USERS[_id]
        elif bucket == 'games':
            del self.GAMES[_id]
        raise KeyError  # No such bucket

    def find(self, bucket, value, key=None):
        if key is None:
            # Why not do this in the function def?
            # Because then you can't search for "None" as a key
            key = '_id'
        if bucket == 'users':
            return (user for user in self.USERS.values() if (value == user.get(key)))
        elif bucket == 'games':
            return (game for game in self.GAMES.values() if (value == game.get(key)))

db = TestDB()