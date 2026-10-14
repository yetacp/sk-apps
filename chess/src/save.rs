//! Bounded on-disk representation of a Chess game.

use crate::engine::position;
use crate::game::{Difficulty, Opponent};

const STATE_LIMIT: usize = 64 * 1024;
const HISTORY_LIMIT: usize = 512;
const VERSION: &str = "chess-v6";

pub(crate) struct SavedGame {
    pub(crate) opponent: Opponent,
    pub(crate) difficulty: Difficulty,
    pub(crate) finished: Option<String>,
    pub(crate) flipped: bool,
    pub(crate) fen: String,
    pub(crate) history: Vec<String>,
    pub(crate) moves: Vec<String>,
}

pub(crate) fn encode(saved: &SavedGame) -> String {
    format!(
        "{VERSION}\n{}\n{}\n{}\n{}\n{}\n{}\n{}",
        saved.opponent.encoded(),
        saved.difficulty.encoded(),
        saved.finished.as_deref().unwrap_or("-"),
        if saved.flipped { "black" } else { "white" },
        saved.fen,
        saved.history.join("\u{1f}"),
        saved.moves.join("\u{1f}")
    )
}

pub(crate) fn decode(text: &str) -> Option<SavedGame> {
    if text.len() > STATE_LIMIT {
        return None;
    }
    let mut fields = text.splitn(8, '\n');
    if fields.next()? != VERSION {
        return None;
    }
    let opponent = Opponent::decode(fields.next()?)?;
    let difficulty = Difficulty::decode(fields.next()?)?;
    let finished = decode_result(fields.next()?).ok()?;
    let flipped = match fields.next()? {
        "white" => false,
        "black" => true,
        _ => return None,
    };
    let fen = fields.next()?.to_owned();
    position(&fen)?;
    let history = fields
        .next()?
        .split('\u{1f}')
        .map(str::to_owned)
        .collect::<Vec<_>>();
    let moves = fields
        .next()?
        .split('\u{1f}')
        .filter(|movement| !movement.is_empty())
        .map(str::to_owned)
        .collect::<Vec<_>>();
    valid_history(&fen, &history, &moves).then_some(SavedGame {
        opponent,
        difficulty,
        finished,
        flipped,
        fen,
        history,
        moves,
    })
}

fn decode_result(value: &str) -> Result<Option<String>, ()> {
    match value {
        "-" => Ok(None),
        "Draw — agreed" | "White resigned — Black wins" | "Black resigned — White wins" => {
            Ok(Some(value.to_owned()))
        }
        _ => Err(()),
    }
}

fn valid_history(fen: &str, history: &[String], moves: &[String]) -> bool {
    !history.is_empty()
        && history.len() <= HISTORY_LIMIT
        && history.last().is_some_and(|saved| saved == fen)
        && history.iter().all(|saved| position(saved).is_some())
        && moves.len().saturating_add(1) == history.len()
        && moves.iter().all(|movement| valid_move_text(movement))
}

fn valid_move_text(movement: &str) -> bool {
    !movement.is_empty()
        && movement.len() <= 32
        && !movement.contains('\n')
        && !movement.contains('\u{1f}')
}
