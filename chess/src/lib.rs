//! Chess rules, bounded local search, and validated game state for the StartK app.
//!
//! This crate has no filesystem, network, UI, or platform access. The future
//! Rust app adapter owns IPC and sends this domain state to `startkd`.

mod engine;
mod game;
mod save;

use crate::engine::piece_at;
use crate::game::{Game, Opponent};

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum Action {
    Square(String),
    Promote(char),
    Undo,
    NewGame,
    ToggleOpponent,
    CycleDifficulty,
    FlipBoard,
    AgreeDraw,
    Resign,
    Confirm(bool),
}

/// Immutable view model for rendering by the StartK declarative UI.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct GameView {
    pub squares: [Option<char>; 64],
    pub selected: Option<String>,
    pub destinations: Vec<String>,
    pub flipped: bool,
    pub status: String,
    pub notice: Option<String>,
    pub last_move: Option<String>,
    pub outcome: Option<String>,
    pub opponent: &'static str,
    pub difficulty: &'static str,
    pub promotion_choices: Vec<char>,
}

/// Rules and game state. It performs no I/O; save strings are passed to the
/// caller so StartK storage remains mediated by `startkd`.
pub struct ChessApp {
    game: Game,
}

impl Default for ChessApp {
    fn default() -> Self {
        Self::new()
    }
}

impl ChessApp {
    pub fn new() -> Self {
        Self { game: Game::default() }
    }

    /// Restore only a complete, validated record. Invalid input leaves state
    /// untouched and returns `false`.
    pub fn restore(&mut self, record: &str) -> bool {
        self.game.decode(record)
    }

    pub fn save(&self) -> String {
        self.game.encode()
    }

    pub fn view(&self) -> GameView {
        let mut squares = [None; 64];
        for rank in (1..=8).rev() {
            for file in b'a'..=b'h' {
                let square = format!("{}{}", char::from(file), rank);
                let index = usize::from(b'8' - rank) * 8 + usize::from(file - b'a');
                squares[index] = piece_at(&self.game.fen, &square);
            }
        }
        let destinations = self.game.selected.as_deref()
            .map(|from| self.game.destinations(from).into_iter().collect())
            .unwrap_or_default();
        GameView {
            squares,
            selected: self.game.selected.clone(),
            destinations,
            flipped: self.game.flipped,
            status: self.game.status(),
            notice: self.game.notice.clone(),
            last_move: self.game.moves.last().cloned(),
            outcome: self.game.outcome(),
            opponent: self.game.opponent.label(),
            difficulty: self.game.difficulty.label(),
            promotion_choices: self.game.promotion.as_ref()
                .map(|promotion| promotion.choices.clone())
                .unwrap_or_default(),
        }
    }

    pub fn dispatch(&mut self, action: Action) {
        let was_square = matches!(&action, Action::Square(_));
        match action {
            Action::Square(square) => self.game.choose_square(square),
            Action::Promote(piece) => self.game.choose_promotion(piece),
            Action::Undo => self.game.undo(),
            Action::NewGame => self.game.confirm(crate::game::Confirmation::Discard),
            Action::ToggleOpponent => self.game.toggle_opponent(),
            Action::CycleDifficulty => self.game.next_difficulty(),
            Action::FlipBoard => self.game.toggle_orientation(),
            Action::AgreeDraw => self.game.confirm(crate::game::Confirmation::Draw),
            Action::Resign => self.game.confirm(crate::game::Confirmation::Resign),
            Action::Confirm(accepted) => self.game.resolve_confirmation(accepted),
        }
        if was_square && self.game.opponent == Opponent::Computer {
            self.game.computer_reply();
        }
    }
}
