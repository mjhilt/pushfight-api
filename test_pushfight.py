import unittest

from pushfight import *


class TestPushfight(unittest.TestCase):
    def test_gen_cardinal_dirs(self):
        self.assertEqual(list(gen_cardinal_dirs()), [(-1, 0), (1, 0), (0, -1), (0, 1)])
    def test_pushes(self):
        pushes = list(EXAMPLE_BOARD.gen_execute_pushes(EXAMPLE_BOARD.pieces))
        for b in pushes:
            self.assertTrue(not b.is_whites_turn)

        self.assertEqual(len(pushes), 2)
        pushes = list(pushes[0].gen_execute_pushes(pushes[0].pieces))
        self.assertEqual(len(pushes), 3)
        pushes = list(pushes[1].gen_execute_pushes(pushes[1].pieces))
        self.assertEqual(len(pushes), 2)

    def test_board(self):
        a = Board(EXAMPLE_BOARD.pieces.copy(), None, True)
        b = Board(EXAMPLE_BOARD.pieces.copy(), None, True)
        self.assertEqual(a, b)

if __name__ == '__main__':
    unittest.main()
