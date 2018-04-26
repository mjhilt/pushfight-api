class Board(object):
    def __init__(self, pieces, anchored, is_whites_turn):
        self.pieces = pieces
        self.anchored = anchored
        self.is_whites_turn = is_whites_turn

    def __hash__(self):
        return hash((tuple(sorted(self.pieces.items())), self.anchored, self.is_whites_turn))

    def __eq__(self, other):
        return (
            (tuple(sorted(self.pieces.items())), self.anchored, self.is_whites_turn) == 
            (tuple(sorted(other.pieces.items())), other.anchored, other.is_whites_turn)
        )

    def gen_neighbors(self, pieces, row, col):
        unexplored = set([(row, col)])
        explored = set(pieces.values())
        def should_explore(r, c):
            key = (r, c)
            return (is_inbounds(r, c) and
                    key not in explored)

        while unexplored:
            row, col = unexplored.pop()
            explored.add((row, col))
            for other_row, other_col in gen_ajacent_ixs(row, col):
                if should_explore(other_row, other_col):
                    yield other_row, other_col
                    unexplored.add((other_row, other_col))

    def gen_next_states(self, pieces=None, nmoves=2):
        pieces = pieces or self.pieces
        yield from self.gen_execute_pushes(pieces)
        if nmoves == 0:
            return

        # for piece, (row, col) in pieces.items():
        #     if 'w' in piece != self.is_whites_turn:
        #         continue
        if self.is_whites_turn:
            movers = ('wp1', 'wp2', 'wp3', 'wm1', 'wm2')
        else:
            movers = ('bp1', 'bp2', 'bp3', 'bm1', 'bm2')

        for mover in movers:
            row, col = pieces[mover]
            for (other_row, other_col) in self.gen_neighbors(pieces, row, col):
                next_pieces = pieces.copy()
                next_pieces[mover] = (other_row, other_col)
                yield from self.gen_next_states(next_pieces, nmoves - 1)

    def gen_execute_pushes(self, pieces):
        if self.is_whites_turn:
            pushers = ('wp1', 'wp2', 'wp3')
        else:
            pushers = ('bp1', 'bp2', 'bp3')
        inverted_pieces = dict(((r, c), p) for p, (r, c) in pieces.items())
        for pusher in pushers:
            row, col = pieces[pusher]
            for dr, dc in gen_cardinal_dirs():
                can_push, pushed_pieces = self.try_push(inverted_pieces, row + dr, col + dc, dr, dc, [pusher])
                if can_push:
                    new_pieces = pieces.copy()
                    for piece in pushed_pieces:
                        r, c = new_pieces[piece]
                        new_pieces[piece] = (r + dr, c + dc)
                    yield Board(new_pieces, anchored=(row + dr, col + dc), is_whites_turn=not self.is_whites_turn)

    def try_push(self, inverted_pieces, row, col, dr, dc, pushed_pieces):
        if (row, col) == self.anchored:
            return False, pushed_pieces

        try:
            piece = inverted_pieces[(row, col)]
        except KeyError:
            if row == -1:
                return not (2 < col < 8) and len(pushed_pieces) > 1, pushed_pieces
            elif row == 4:
                return not (1 < col < 7) and len(pushed_pieces) > 1, pushed_pieces
            else:
                return len(pushed_pieces) > 1, pushed_pieces
        else:
            pushed_pieces.append(piece)
            return self.try_push(inverted_pieces, row + dr, col + dc, dr, dc, pushed_pieces)

    def is_over(self, pieces=None):
        pieces = pieces or self.pieces
        return not all(is_inbounds(r, c) for r, c in pieces.values())

    def vis(self):
        board = [
            ['  ','  ','  ','==','==','==','==','==','  ','  '],
            ['  ','  ','  ','__','__','__','__','__','  ','  '],
            ['  ','__','__','__','__','__','__','__','__','  '],
            ['  ','__','__','__','__','__','__','__','__','  '],
            ['  ','  ','__','__','__','__','__','  ','  ','  '],
            ['  ','  ','==','==','==','==','==','  ','  ','  '],
        ]
        for piece, (row, col) in self.pieces.items():
            if 'm' in piece:
                board[row+1][col] = '{}{}'.format(piece[0].upper(), piece[1])
            else:
                board[row + 1][col] = '{}{}'.format(piece[0].upper(), piece[1].upper())
        if self.anchored is not None:
            row, col = self.anchored
            board[row+1][col] = '{}#'.format(board[row+1][col][0])
        for row in board:
            # print(row)
            print(''.join(row))
        print()


_CARDINAL_DIRS = ((-1, 0), (1, 0), (0, -1), (0, 1))
def gen_cardinal_dirs():
    for direction in _CARDINAL_DIRS:
        yield direction

def gen_ajacent_ixs(row, col):
    for dr, dc in gen_cardinal_dirs():
        yield row + dr, col + dc


def is_inbounds(row, col):
    if row == 0:
        return 2 < col < 8
    elif row == 1 or row == 2:
        return 0 < col < 9
    elif row == 3:
        return 1 < col < 7
    else:
        return False


EXAMPLE_BOARD = Board(
    pieces={
        'wp1': (1, 4),
        'wp2': (2, 4),
        'wp3': (2, 2),
        'wm1': (0, 4),
        'wm2': (3, 4),
        'bp1': (3, 5),
        'bp2': (2, 5),
        'bp3': (0, 5),
        'bm1': (1, 5),
        'bm2': (1, 6)
    },
    anchored=None,
    is_whites_turn=True
)
