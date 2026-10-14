//! Application state, move orchestration, and durable game records.

use crate::engine::{piece_at, position, position_key, promotion_choices, tiny_move};
use crate::save::{self, SavedGame};
use shakmaty::{CastlingMode, EnPassantMode, Position as _, fen::Fen, san::San, uci::UciMove};
use std::collections::BTreeSet;

pub(crate) const START: &str = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

#[derive(Clone, Copy, Default, Eq, PartialEq)]
pub(crate) enum Opponent {
    #[default]
    Local,
    Computer,
}

impl Opponent {
    pub(crate) fn encoded(self) -> &'static str {
        match self {
            Self::Local => "local",
            Self::Computer => "computer",
        }
    }
    pub(crate) fn decode(value: &str) -> Option<Self> {
        match value {
            "local" => Some(Self::Local),
            "computer" => Some(Self::Computer),
            _ => None,
        }
    }
    pub(crate) fn label(self) -> &'static str {
        match self {
            Self::Local => "Two players",
            Self::Computer => "Kobo plays Black",
        }
    }
    fn other(self) -> Self {
        match self {
            Self::Local => Self::Computer,
            Self::Computer => Self::Local,
        }
    }
}

#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub(crate) enum Difficulty {
    Easy,
    #[default]
    Standard,
    Challenging,
}

impl Difficulty {
    pub(crate) fn encoded(self) -> &'static str {
        match self {
            Self::Easy => "easy",
            Self::Standard => "standard",
            Self::Challenging => "challenging",
        }
    }
    pub(crate) fn decode(value: &str) -> Option<Self> {
        match value {
            "easy" => Some(Self::Easy),
            "standard" => Some(Self::Standard),
            "challenging" => Some(Self::Challenging),
            _ => None,
        }
    }
    pub(crate) fn label(self) -> &'static str {
        match self {
            Self::Easy => "Easy",
            Self::Standard => "Standard",
            Self::Challenging => "Challenging",
        }
    }
    fn next(self) -> Self {
        match self {
            Self::Easy => Self::Standard,
            Self::Standard => Self::Challenging,
            Self::Challenging => Self::Easy,
        }
    }
    pub(crate) fn limits(self) -> (u8, u32) {
        match self {
            Self::Easy => (1, 250),
            Self::Standard => (3, 2_000),
            Self::Challenging => (4, 5_000),
        }
    }
}

#[derive(Clone)]
pub(crate) struct Promotion {
    pub(crate) from: String,
    pub(crate) to: String,
    pub(crate) choices: Vec<char>,
}

pub(crate) struct Game {
    pub(crate) fen: String,
    pub(crate) history: Vec<String>,
    pub(crate) moves: Vec<String>,
    pub(crate) selected: Option<String>,
    pub(crate) promotion: Option<Promotion>,
    pub(crate) notice: Option<String>,
    pub(crate) opponent: Opponent,
    pub(crate) difficulty: Difficulty,
    pub(crate) finished: Option<String>,
    pub(crate) confirmation: Option<Confirmation>,
    pub(crate) flipped: bool,
}

#[derive(Clone, Copy)]
pub(crate) enum Confirmation {
    Resign,
    Draw,
    Discard,
}

impl Default for Game {
    fn default() -> Self {
        Self {
            fen: START.to_owned(),
            history: vec![START.to_owned()],
            moves: Vec::new(),
            selected: None,
            promotion: None,
            notice: None,
            opponent: Opponent::default(),
            difficulty: Difficulty::default(),
            finished: None,
            confirmation: None,
            flipped: false,
        }
    }
}

impl Game {
    pub(crate) fn reset(&mut self) {
        let opponent = self.opponent;
        let difficulty = self.difficulty;
        let flipped = self.flipped;
        *self = Self::default();
        self.opponent = opponent;
        self.difficulty = difficulty;
        self.flipped = flipped;
    }

    pub(crate) fn encode(&self) -> String {
        save::encode(&self.saved())
    }

    /// Validates the complete record before replacing in-memory state.
    pub(crate) fn decode(&mut self, text: &str) -> bool {
        let Some(saved) = save::decode(text) else {
            return false;
        };
        self.apply_saved(saved);
        self.selected = None;
        self.promotion = None;
        self.confirmation = None;
        true
    }

    fn saved(&self) -> SavedGame {
        SavedGame {
            opponent: self.opponent,
            difficulty: self.difficulty,
            finished: self.finished.clone(),
            flipped: self.flipped,
            fen: self.fen.clone(),
            history: self.history.clone(),
            moves: self.moves.clone(),
        }
    }

    fn apply_saved(&mut self, saved: SavedGame) {
        self.fen = saved.fen;
        self.history = saved.history;
        self.moves = saved.moves;
        self.opponent = saved.opponent;
        self.difficulty = saved.difficulty;
        self.finished = saved.finished;
        self.flipped = saved.flipped;
    }

    pub(crate) fn side_to_move(&self) -> Option<char> {
        self.fen
            .split_whitespace()
            .nth(1)
            .and_then(|side| match side {
                "w" => Some('w'),
                "b" => Some('b'),
                _ => None,
            })
    }

    pub(crate) fn outcome(&self) -> Option<String> {
        if self.finished.is_some() {
            return self.finished.clone();
        }
        let position = position(&self.fen)?;
        if position.is_checkmate() {
            return Some(match self.side_to_move()? {
                'w' => "Checkmate — Black wins".to_owned(),
                'b' => "Checkmate — White wins".to_owned(),
                _ => return None,
            });
        }
        if position.is_stalemate() {
            return Some("Draw — stalemate".to_owned());
        }
        if position.is_insufficient_material() {
            return Some("Draw — insufficient material".to_owned());
        }
        if self
            .fen
            .split_whitespace()
            .nth(4)
            .and_then(|clock| clock.parse::<u16>().ok())
            .is_some_and(|clock| clock >= 100)
        {
            return Some("Draw — fifty-move rule".to_owned());
        }
        let key = position_key(&self.fen);
        if self
            .history
            .iter()
            .filter(|saved| position_key(saved) == key)
            .count()
            >= 3
        {
            Some("Draw — threefold repetition".to_owned())
        } else {
            None
        }
    }

    pub(crate) fn status(&self) -> String {
        if let Some(outcome) = self.outcome() {
            return outcome;
        }
        let turn = match self.side_to_move() {
            Some('w') => "White to move",
            Some('b') => "Black to move",
            _ => "Position unavailable",
        };
        if position(&self.fen).is_some_and(|current| current.is_check()) {
            format!("{turn} — check")
        } else {
            turn.to_owned()
        }
    }

    pub(crate) fn destinations(&self, from: &str) -> BTreeSet<String> {
        let Some(current) = position(&self.fen) else {
            return BTreeSet::new();
        };
        current
            .legal_moves()
            .iter()
            .map(|movement| movement.to_uci(CastlingMode::Standard).to_string())
            .filter(|movement| movement.starts_with(from))
            .filter_map(|movement| movement.get(2..4).map(str::to_owned))
            .collect()
    }

    pub(crate) fn choose_square(&mut self, square: String) {
        if self.outcome().is_some() {
            self.notice = Some("Start a new game to keep playing.".to_owned());
            return;
        }
        let Some(piece) = piece_at(&self.fen, &square) else {
            if self
                .selected
                .as_deref()
                .is_some_and(|from| self.destinations(from).contains(&square))
            {
                let from = self.selected.clone().unwrap_or_default();
                let choices = promotion_choices(&self.fen, &from, &square);
                if choices.is_empty() {
                    self.play(&format!("{from}{square}"));
                } else {
                    self.promotion = Some(Promotion {
                        from,
                        to: square,
                        choices,
                    });
                }
            } else {
                self.notice = Some("Choose a piece or a marked destination.".to_owned());
            }
            return;
        };
        let own_piece = matches!(
            (self.side_to_move(), piece.is_ascii_uppercase()),
            (Some('w'), true) | (Some('b'), false)
        );
        let Some(from) = self.selected.clone() else {
            if own_piece {
                self.selected = Some(square);
                self.notice = None;
            } else {
                self.notice = Some("Choose a piece whose turn it is.".to_owned());
            }
            return;
        };
        if square == from {
            self.selected = None;
            self.notice = None;
        } else if own_piece {
            self.selected = Some(square);
            self.notice = None;
        } else if self.destinations(&from).contains(&square) {
            let choices = promotion_choices(&self.fen, &from, &square);
            if choices.is_empty() {
                self.play(&format!("{from}{square}"));
            } else {
                self.promotion = Some(Promotion {
                    from,
                    to: square,
                    choices,
                });
            }
        } else {
            self.notice = Some("That move is not legal.".to_owned());
        }
    }

    pub(crate) fn choose_promotion(&mut self, choice: char) {
        let Some(promotion) = self.promotion.take() else {
            return;
        };
        if promotion.choices.contains(&choice) {
            self.play(&format!("{}{}{}", promotion.from, promotion.to, choice));
        }
    }

    fn play(&mut self, uci: &str) {
        let Some(current) = position(&self.fen) else {
            self.notice = Some("The saved position could not be read.".to_owned());
            return;
        };
        let Some(movement) = UciMove::from_ascii(uci.as_bytes())
            .ok()
            .and_then(|move_text| move_text.to_move(&current).ok())
        else {
            self.notice = Some("That move is not legal.".to_owned());
            return;
        };
        let san = San::from_move(&current, &movement).to_string();
        let Ok(next) = current.play(&movement) else {
            self.notice = Some("That move could not be applied.".to_owned());
            return;
        };
        self.fen = Fen::from_position(next, EnPassantMode::Legal).to_string();
        self.history.push(self.fen.clone());
        self.moves.push(san);
        self.selected = None;
        self.notice = None;
    }

    pub(crate) fn undo(&mut self) {
        if self.history.len() <= 1 {
            self.notice = Some("This is the first position.".to_owned());
            return;
        }
        let plies = if self.opponent == Opponent::Computer
            && self.side_to_move() == Some('w')
            && self.history.len() > 2
        {
            2
        } else {
            1
        };
        for _ in 0..plies {
            self.history.pop();
            self.moves.pop();
        }
        self.fen = self
            .history
            .last()
            .cloned()
            .unwrap_or_else(|| START.to_owned());
        self.selected = None;
        self.promotion = None;
        self.notice = None;
    }

    pub(crate) fn toggle_opponent(&mut self) {
        self.opponent = self.opponent.other();
        self.reset();
        self.notice = Some(match self.opponent {
            Opponent::Local => "Two-player game ready.".to_owned(),
            Opponent::Computer => "You play White. Kobo plays Black.".to_owned(),
        });
    }

    pub(crate) fn computer_reply(&mut self) {
        if self.opponent != Opponent::Computer
            || self.side_to_move() != Some('b')
            || self.outcome().is_some()
        {
            return;
        }
        let Some(movement) = tiny_move(&self.fen, self.difficulty) else {
            self.notice = Some("Kobo could not find a legal move.".to_owned());
            return;
        };
        self.play(&movement);
        if let Some(last) = self.moves.last() {
            self.notice = Some(format!("Kobo played {last}."));
        }
    }

    pub(crate) fn next_difficulty(&mut self) {
        self.difficulty = self.difficulty.next();
        self.notice = Some(format!("Kobo difficulty: {}.", self.difficulty.label()));
    }

    pub(crate) fn toggle_orientation(&mut self) {
        self.flipped = !self.flipped;
        self.selected = None;
        self.notice = Some(if self.flipped {
            "Board: Black at the bottom.".to_owned()
        } else {
            "Board: White at the bottom.".to_owned()
        });
    }

    pub(crate) fn confirm(&mut self, what: Confirmation) {
        self.confirmation = Some(what);
    }

    pub(crate) fn resolve_confirmation(&mut self, accepted: bool) {
        let Some(what) = self.confirmation.take() else {
            return;
        };
        if !accepted {
            return;
        }
        match what {
            Confirmation::Discard => self.reset(),
            Confirmation::Draw => self.finished = Some("Draw — agreed".to_owned()),
            Confirmation::Resign => {
                self.finished = Some(
                    match self.side_to_move() {
                        Some('w') => "White resigned — Black wins",
                        _ => "Black resigned — White wins",
                    }
                    .to_owned(),
                );
            }
        }
        self.selected = None;
        self.promotion = None;
    }
}
