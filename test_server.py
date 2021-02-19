# import base64
import server
import bottle as b
from utils import b64encode

from boddle import boddle

def test_login():
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
        server.login()
        # TODO can't figure out how to inspect cookies, I'm sure it's fine

def test_check_user():
    with boddle(headers={"Authorization": "Basic " + b64encode("a"+":"+b64encode("c"))}):
        res = server.check_user()
        assert res.body == "a"

    with boddle(headers={"Authorization": "Basic " + b64encode("a"+":"+b64encode("badpw"))}):
        res = server.check_user()
        assert res.body == "a"


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
    test_login()
    test_check_user()