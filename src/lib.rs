#![feature(proc_macro, wasm_custom_section, wasm_import_module)]

extern crate wasm_bindgen;
use std::fmt;
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
    WhitePusher=0,//{is_anchored: bool},
    WhiteMover=1,
    BlackPusher=2,//{is_anchored: bool},
    BlackMover=3,
    Empty=4,
    Abyss=5
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
}

/// Public methods, exported to JavaScript.
#[wasm_bindgen]
impl Universe {
/*
    pub fn tick(&mut self) {
        let mut next = self.cells.clone();

        for row in 0..self.height {
            for col in 0..self.width {
                let idx = self.get_index(row, col);
                let cell = self.cells[idx];
                let live_neighbors = self.live_neighbor_count(row, col);

                let next_cell = match (cell, live_neighbors) {
                    // Rule 1: Any live cell with fewer than two live neighbours
                    // dies, as if caused by underpopulation.
                    (Cell::Alive, x) if x < 2 => Cell::Dead,
                    // Rule 2: Any live cell with two or three live neighbours
                    // lives on to the next generation.
                    (Cell::Alive, 2) | (Cell::Alive, 3) => Cell::Alive,
                    // Rule 3: Any live cell with more than three live
                    // neighbours dies, as if by overpopulation.
                    (Cell::Alive, x) if x > 3 => Cell::Dead,
                    // Rule 4: Any dead cell with exactly three live neighbours
                    // becomes a live cell, as if by reproduction.
                    (Cell::Dead, 3) => Cell::Alive,
                    // All other cells remain in the same state.
                    (otherwise, _) => otherwise,
                };

                next[idx] = next_cell;
            }
        }

        self.cells = next;
    }

*/
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

    pub fn render(&self) -> String {
        self.to_string()
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
        // if self.can_move(start_row, start_column, end_row, end_column) {
        //     self.pieces[self.get_index(end_row, end_column)] = self.pieces[self.get_index(start_row, start_column)];
        // }
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

        // return;

        // let mut other_pieces = self.pieces.clone();
        if let Some((to_ix, from_ix)) = indices {
            self.pieces[to_ix] = self.pieces[from_ix];
            log!("moving {} -> {}", from_ix, to_ix);
            self.pieces[from_ix] = Piece::Empty;
        }
        // Universe{width: self.width, height: self.height, pieces: other_pieces}
    }
}

impl fmt::Display for Universe {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        for line in self.pieces.as_slice().chunks(self.width as usize) {
            for &piece in line {
                let symbol = if piece == Piece::Abyss { "◻️" } else { "◼️" };
                write!(f, "{}", symbol)?;
            }
            write!(f, "\n")?;
        }

        Ok(())
    }
}

