# import base64
import server
import bottle as b
from utils import b64encode
from db_interface import db

from boddle import boddle

token = None

def test_register():
    with boddle(json={'email': "TeaUponTweed@gmail.com", "password": "salted:hashed_password"}):
        try:
            res = server.register()
        except b.HTTPError as e:
            assert False
        assert res.get('username') == 1

    with boddle(json={'email': "TeaUponTweed@gmail.com", "password": "salted:hashed_password"}):
        try:
            res = server.register()
        except b.HTTPError as e:
            assert e.status_code == 400

def test_login():
    global token
    with boddle(json={'user': "TeaUponTweed@gmail.com"}):
        # print(b.request.json)
        try:
            server.login()
        except b.HTTPError as e:
            assert e.status_code == 400
            # print(e)

    with boddle(json={'user': "TeaUponTweed@gmail.com", 'password': b64encode('wrong')}):
        # print(b.request.json)
        try:
            server.login()
        except b.HTTPError as e:
            assert e.status_code == 403

    with boddle(json={'user': "TeaUponTweed@gmail.com", 'password': b64encode("salted:hashed_password")}):
        res = server.login()
        assert res.get('username') == "TeaUponTweed@gmail.com"
        assert 'token' in res
        token = res['token']

def test_check_user():
    global token
    with boddle(headers={"Authorization": "Basic " + b64encode("a"+":"+"c")}):
        res = server.check_user()
        assert res.status_code == 401

    with boddle(headers={"Authorization": "Basic " + b64encode("TeaUponTweed@gmail.com"+":"+token)}):
        res = server.check_user()
        assert res.body == "TeaUponTweed@gmail.com"


def test_opengames():
    pass

def test_game_challenge():
    pass

def test_game_start():
    pass

def test_game_join():
    pass

def test_game_status():
    pass

def test_move():
    pass


if __name__ == '__main__':
    server.load_session_key()
    test_register()
    test_login()
    test_check_user()