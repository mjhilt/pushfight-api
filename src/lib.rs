#![feature(proc_macro, wasm_custom_section, wasm_import_module)]

extern crate wasm_bindgen;
use std::collections::HashSet;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
extern {
    fn alert(s: &str);
}

#[wasm_bindgen]
pub fn greet(name: &str) {
    alert(&format!("Hello, {}!", name));
}


#[repr(u8)]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Piece {
    WhitePusher=0,
    WhiteMover=1,
    BlackPusher=2,
    BlackMover=3,
    Empty=4,
    Abyss=5,
    AnchoredWhitePusher=6,
    AnchoredBlackPusher=7
}

#[wasm_bindgen]
pub struct Universe {
    width: u32,
    height: u32,
    pieces: Vec<Piece>
}

#[wasm_bindgen]
extern {
    #[wasm_bindgen(js_namespace = console)]
    fn log(msg: &str);
}

// A macro to provide `println!(..)`-style syntax for `console.log` logging.
macro_rules! log {
    ($($t:tt)*) => (log(&format!($($t)*)))
}

impl Universe {
    fn get_index(&self, row: u32, column: u32) -> usize {
        (row * self.width + column) as usize
    }
    fn in_bounds(&self, row: i32, col: i32) -> bool {
        return row >= 0 && row < self.height as i32 && col >= 0 && col < self.width as i32;
    }
    fn valid_step(&self, to_row: i32, to_column: i32) -> bool {
        return self.in_bounds(to_row, to_column) && self.pieces[self.get_index(to_row as u32, to_column as u32)] == Piece::Empty;
    }
    fn can_move(&self, start_row: u32, start_column: u32, end_row: u32, end_column: u32) -> bool {
        if start_row == end_row && start_column == end_column {
            return false;
        }
        if !self.in_bounds(start_row as i32, start_column as i32) {
            log("start row({}) col({}) not in bounds");
            return false;
        }
        if !self.in_bounds(end_row as i32, end_column as i32) {
            log("end row({}) col({}) not in bounds");
            return false;
        }
        if 
            (self.pieces[self.get_index(start_row, start_column)] == Piece::Empty) ||
            (self.pieces[self.get_index(start_row, start_column)] == Piece::Abyss) {
            return false;
        }
        let mut to_explore = Vec::new();
        to_explore.push((start_row as i32, start_column as i32));
        let mut have_explored = HashSet::new();
        while let Some((row, column)) = to_explore.pop() {
            if row == end_row as i32 && column == end_column as i32 {
                return true;
            }
            have_explored.insert((row, column));
            for (delta_row, delta_column) in [(-1, 0), (0, -1), (1, 0), (0, 1)].iter().cloned() {
                let next_row = row as i32 + delta_row; 
                let next_column = column as i32 + delta_column; 
                if self.valid_step(next_row, next_column) && !have_explored.contains(&(next_row, next_column)) {
                    to_explore.push((next_row, next_column));
                }
            }
        }
        return false;
    }
    fn can_push(&self, row: i32, column: i32, delta_row: i32, delta_col: i32) -> bool {
        if !self.in_bounds(row, column) {
            log!("{} {} not in bounds for push", row, column);
            return false;
        }
        if (delta_row.abs() + delta_col.abs()) != 1 {
            log!("Invalid push dir {} {}", delta_col, delta_row);
            return false;
        }
        let ix = self.get_index(row as u32, column as u32);
        if (self.pieces[ix] != Piece::BlackPusher) && (self.pieces[ix] != Piece::WhitePusher) {
            log!("Mush push with pusher not {:?}", self.pieces[ix]);
            return false;
        }
        let mut r = row + delta_row;
        let mut c = column + delta_col;
        while self.in_bounds(r, c) {
            match self.pieces[self.get_index(r as u32, c as u32)] {
                Piece::AnchoredBlackPusher |  Piece::AnchoredWhitePusher => {
                    log!("Can't push through anchor");
                    return false
                },
                Piece::Empty |  Piece::Abyss => return (r - row).abs() + (c - column).abs() > 1,
                _ => {}
            }
            r += delta_row;
            c += delta_col;
        }
        log!("Push ended out of bounds. This is not allowed");
        false
    }
    fn execute_push(&mut self, row: i32, column: i32, delta_row: i32, delta_col: i32) {
        let mut last_piece = Piece::Empty;
        let mut r = row;
        let mut c = column;
        let mut new_pieces = self.pieces.clone();
        while self.in_bounds(r, c) {
            let ix = self.get_index(r as u32, c as u32);
            match self.pieces[ix] {
                Piece::Empty => {
                    // last_piece = p;
                    new_pieces[ix] = last_piece;
                    log!("a");
                    break;
                },
                Piece::Abyss => {
                    log!("b");
                    break;
                    // last_piece = p;
                    // new_pieces[ix] = last_piece;
                    // self.game_over = true;
                },
                _ => {
                    log!("c");
                    new_pieces[ix] = last_piece;
                    last_piece = self.pieces[self.get_index(r as u32, c as u32)];
                }
            }

            r += delta_row;
            c += delta_col;
            log!("d {} {} ", r, c);
        }
        let old_ix = self.get_index(row as u32, column as u32);
        let new_ix = self.get_index((row + delta_row) as u32, (column + delta_col) as u32);
        new_pieces[new_ix] = {
            match self.pieces[old_ix] {
                Piece::WhitePusher => Piece::AnchoredWhitePusher,
                Piece::BlackPusher => Piece::AnchoredBlackPusher,
                _ => Piece::Abyss // This should not happen
            }
        };
        self.pieces = new_pieces;
    }
}

/// Public methods, exported to JavaScript.
#[wasm_bindgen]
impl Universe {
    pub fn new() -> Universe {
        let width = 10;
        let height = 4;

        let pieces = vec![
            Piece::Abyss, Piece::Abyss, Piece::Abyss      , Piece::Empty, Piece::BlackPusher, Piece::WhiteMover , Piece::Empty, Piece::Empty      , Piece::Abyss, Piece::Abyss,
            Piece::Abyss, Piece::Empty, Piece::Empty      , Piece::Empty, Piece::BlackMover , Piece::WhitePusher, Piece::Empty, Piece::Empty      , Piece::Empty, Piece::Abyss,
            Piece::Abyss, Piece::Empty, Piece::BlackPusher, Piece::Empty, Piece::BlackMover , Piece::WhitePusher, Piece::Empty, Piece::WhitePusher, Piece::Empty, Piece::Abyss,
            Piece::Abyss, Piece::Abyss, Piece::Empty      , Piece::Empty, Piece::BlackPusher, Piece::WhiteMover , Piece::Empty, Piece::Abyss      , Piece::Abyss, Piece::Abyss,
        ];
        assert!(width * height == pieces.len() as u32);
        Universe {
            width,
            height,
            pieces
        }
    }

    pub fn width(&self) -> u32 {
        self.width
    }

    pub fn height(&self) -> u32 {
        self.height
    }

    pub fn cells(&self) -> *const Piece {
        self.pieces.as_ptr()
    }

    pub fn try_move(&mut self, start_row: u32, start_column: u32, end_row: u32, end_column: u32) {
        let indices = {
            if self.can_move(start_row, start_column, end_row, end_column) {
                let from_ix = self.get_index(start_row, start_column);
                let to_ix = self.get_index(end_row, end_column);
                Some((to_ix, from_ix))
            }
            else
            {
                None
            }
        };

        if let Some((to_ix, from_ix)) = indices {
            self.pieces[to_ix] = self.pieces[from_ix];
            log!("moving {} -> {}", from_ix, to_ix);
            self.pieces[from_ix] = Piece::Empty;
            return;
        }
        let pushdir = {
            let delta_row = (end_row as i32)-(start_row as i32);
            let delta_col = (end_column as i32)-(start_column as i32);
            if self.can_push(start_row as i32, start_column as i32, delta_row, delta_col) {
                Some((delta_row, delta_col))
            }
            else {
                None
            }
        };
        if let Some((delta_row, delta_col)) = pushdir {
            log!("Push is valid from {} {} in {} {} direction", start_column, start_row, delta_col, delta_row);

            self.execute_push(start_row as i32, start_column as i32, delta_row, delta_col);
        }
    }
}
