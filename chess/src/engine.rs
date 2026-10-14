//! Chess rules and the bounded, deterministic local search.

use crate::game::Difficulty;
use shakmaty::{
    fen::Fen, uci::UciMove, CastlingMode, Chess as Position, EnPassantMode, Position as _,
};

const MATE: i32 = 100_000;
const QUIESCENCE_DEPTH: u8 = 8;
const ASPIRATION_WINDOW: i32 = 50;
// A fixed, deliberately small table keeps the search's memory use predictable
// on readers. Each entry retains its complete position key, so a collision is
// only a missed cache opportunity, never a wrong score.
const TRANSPOSITION_ENTRIES: usize = 256;

#[derive(Clone, Copy)]
enum Bound {
    Exact,
    Lower,
    Upper,
}

#[derive(Clone)]
struct TranspositionEntry {
    key: u64,
    depth: u8,
    score: i32,
    bound: Bound,
    best_move: String,
}

struct SearchState {
    nodes: u32,
    max_nodes: u32,
    table: Vec<Option<TranspositionEntry>>,
    // Per-search quiet-move history. It is fixed-size and deliberately not
    // persisted, so it cannot affect saved games or reader memory over time.
    history: [[i16; 64]; 64],
}

impl SearchState {
    fn new(max_nodes: u32) -> Self {
        Self {
            nodes: 0,
            max_nodes,
            table: vec![None; TRANSPOSITION_ENTRIES],
            history: [[0; 64]; 64],
        }
    }

    fn visit(&mut self) -> Option<()> {
        if self.nodes >= self.max_nodes {
            None
        } else {
            self.nodes = self.nodes.saturating_add(1);
            Some(())
        }
    }

    fn entry(&self, key: u64) -> Option<&TranspositionEntry> {
        self.table[usize::from(key.to_le_bytes()[0]) % self.table.len()]
            .as_ref()
            .filter(|entry| entry.key == key)
    }

    fn store(&mut self, entry: TranspositionEntry) {
        let slot = usize::from(entry.key.to_le_bytes()[0]) % self.table.len();
        if self.table[slot]
            .as_ref()
            .is_none_or(|old| old.key == entry.key || entry.depth >= old.depth)
        {
            self.table[slot] = Some(entry);
        }
    }

    fn reward_quiet_cutoff(&mut self, uci: &str, depth: u8) {
        let Some((from, to)) = move_squares(uci) else {
            return;
        };
        let bonus = i16::from(depth).saturating_mul(i16::from(depth));
        self.history[from][to] = self.history[from][to].saturating_add(bonus);
    }
}

pub(crate) fn position(fen: &str) -> Option<Position> {
    fen.parse::<Fen>()
        .ok()?
        .into_position(CastlingMode::Standard)
        .ok()
}

pub(crate) fn position_key(fen: &str) -> String {
    fen.split_whitespace().take(4).collect::<Vec<_>>().join(" ")
}

pub(crate) fn piece_at(fen: &str, square: &str) -> Option<char> {
    let bytes = square.as_bytes();
    if bytes.len() != 2 || !matches!(bytes[0], b'a'..=b'h') || !matches!(bytes[1], b'1'..=b'8') {
        return None;
    }
    let wanted_file = usize::from(bytes[0] - b'a');
    let wanted_rank = usize::from(b'8' - bytes[1]);
    let rank = fen.split_whitespace().next()?.split('/').nth(wanted_rank)?;
    let mut file = 0_usize;
    for character in rank.chars() {
        if let Some(empty) = character.to_digit(10) {
            file += usize::try_from(empty).ok()?;
        } else {
            if file == wanted_file {
                return Some(character);
            }
            file += 1;
        }
    }
    None
}

pub(crate) fn promotion_choices(fen: &str, from: &str, to: &str) -> Vec<char> {
    if !matches!(
        (piece_at(fen, from), to.as_bytes().get(1)),
        (Some('P'), Some(b'8')) | (Some('p'), Some(b'1'))
    ) {
        return Vec::new();
    }
    ['q', 'r', 'b', 'n']
        .into_iter()
        .filter(|choice| legal(fen, &format!("{from}{to}{choice}")))
        .collect()
}

pub(crate) fn legal(fen: &str, uci: &str) -> bool {
    let Some(current) = position(fen) else {
        return false;
    };
    UciMove::from_ascii(uci.as_bytes())
        .ok()
        .and_then(|movement| movement.to_move(&current).ok())
        .is_some()
}

/// A predictable local opponent. Its bounds prioritize panel responsiveness
/// over engine strength.
pub(crate) fn tiny_move(fen: &str, difficulty: Difficulty) -> Option<String> {
    let (max_depth, max_nodes) = difficulty.limits();
    let current = position(fen)?;
    let mut state = SearchState::new(max_nodes);
    let mut chosen = ordered_moves(&current, None, Some(&state.history))
        .first()
        .map(|(uci, _)| uci.clone())?;
    let mut previous_score = None;
    for depth in 1..=max_depth {
        let Some((score, movement)) =
            search_iteration(&current, depth, &chosen, previous_score, &mut state)
        else {
            // Do not let a partial iteration replace the last fully searched move.
            break;
        };
        chosen = movement;
        previous_score = Some(score);
    }
    Some(chosen)
}

fn search_iteration(
    current: &Position,
    depth: u8,
    preferred: &str,
    previous_score: Option<i32>,
    state: &mut SearchState,
) -> Option<(i32, String)> {
    let Some(previous_score) = previous_score else {
        return root_search(current, depth, -MATE, MATE, preferred, state);
    };
    let alpha = (previous_score - ASPIRATION_WINDOW).max(-MATE);
    let beta = (previous_score + ASPIRATION_WINDOW).min(MATE);
    let (score, movement) = root_search(current, depth, alpha, beta, preferred, state)?;
    if score <= alpha || score >= beta {
        // A failed narrow window is only a bound. Re-searching widely keeps the
        // committed iteration exact; a node-budget abort returns None instead.
        root_search(current, depth, -MATE, MATE, preferred, state)
    } else {
        Some((score, movement))
    }
}

fn root_search(
    current: &Position,
    depth: u8,
    mut alpha: i32,
    beta: i32,
    preferred: &str,
    state: &mut SearchState,
) -> Option<(i32, String)> {
    let mut best = None;
    for (uci, movement) in ordered_moves(current, Some(preferred), Some(&state.history)) {
        let next = current.clone().play(&movement).ok()?;
        let score = -tiny_search(&next, depth.saturating_sub(1), -beta, -alpha, 1, state)?;
        if best.as_ref().is_none_or(|(best_score, best_uci)| {
            score > *best_score || score == *best_score && uci < *best_uci
        }) {
            best = Some((score, uci));
        }
        alpha = alpha.max(score);
        if alpha >= beta {
            break;
        }
    }
    best
}

fn tiny_search(
    current: &Position,
    depth: u8,
    mut alpha: i32,
    beta: i32,
    ply: u8,
    state: &mut SearchState,
) -> Option<i32> {
    state.visit()?;
    if current.legal_moves().is_empty() {
        return Some(if current.is_check() {
            -MATE + i32::from(ply)
        } else {
            0
        });
    }
    if depth == 0 {
        return quiesce(current, alpha, beta, ply, QUIESCENCE_DEPTH, state);
    }

    let key = search_key(current);
    let original_alpha = alpha;
    let original_beta = beta;
    let hash_move = state.entry(key).map(|entry| entry.best_move.clone());
    if let Some(entry) = state.entry(key).filter(|entry| entry.depth >= depth) {
        match entry.bound {
            Bound::Exact => return Some(entry.score),
            Bound::Lower if entry.score >= beta => return Some(entry.score),
            Bound::Upper if entry.score <= alpha => return Some(entry.score),
            Bound::Lower | Bound::Upper => {}
        }
    }

    let mut best = i32::MIN + 1;
    let mut best_move = String::new();
    for (uci, movement) in ordered_moves(current, hash_move.as_deref(), Some(&state.history)) {
        let next = current.clone().play(&movement).ok()?;
        let score = -tiny_search(
            &next,
            depth - 1,
            -beta,
            -alpha,
            ply.saturating_add(1),
            state,
        )?;
        if score > best {
            best = score;
            best_move = uci;
        }
        alpha = alpha.max(score);
        if alpha >= beta {
            if !is_tactical(current, &best_move) {
                state.reward_quiet_cutoff(&best_move, depth);
            }
            break;
        }
    }
    state.store(TranspositionEntry {
        key,
        depth,
        score: best,
        bound: if best <= original_alpha {
            Bound::Upper
        } else if best >= original_beta {
            Bound::Lower
        } else {
            Bound::Exact
        },
        best_move,
    });
    Some(best)
}

fn quiesce(
    current: &Position,
    mut alpha: i32,
    beta: i32,
    ply: u8,
    remaining: u8,
    state: &mut SearchState,
) -> Option<i32> {
    state.visit()?;
    let moves = current.legal_moves();
    if moves.is_empty() {
        return Some(if current.is_check() {
            -MATE + i32::from(ply)
        } else {
            0
        });
    }
    let in_check = current.is_check();
    let stand_pat = evaluate(current);
    if !in_check {
        if stand_pat >= beta {
            return Some(stand_pat);
        }
        alpha = alpha.max(stand_pat);
    }
    if remaining == 0 {
        return Some(if in_check { stand_pat } else { alpha });
    }
    let mut best = if in_check { i32::MIN + 1 } else { stand_pat };
    for (uci, movement) in ordered_moves_from(current, moves, None, None) {
        if !in_check && !is_tactical(current, &uci) {
            continue;
        }
        let next = current.clone().play(&movement).ok()?;
        let score = -quiesce(
            &next,
            -beta,
            -alpha,
            ply.saturating_add(1),
            remaining - 1,
            state,
        )?;
        best = best.max(score);
        alpha = alpha.max(score);
        if alpha >= beta {
            break;
        }
    }
    Some(best)
}

fn ordered_moves(
    current: &Position,
    preferred: Option<&str>,
    history: Option<&[[i16; 64]; 64]>,
) -> Vec<(String, shakmaty::Move)> {
    ordered_moves_from(current, current.legal_moves(), preferred, history)
}

fn ordered_moves_from(
    current: &Position,
    movements: shakmaty::MoveList,
    preferred: Option<&str>,
    history: Option<&[[i16; 64]; 64]>,
) -> Vec<(String, shakmaty::Move)> {
    // `MoveList` owns the legal moves. Keep ordering separate from generation
    // so quiescence can use the list it already generated for terminal checks.
    let fen = Fen::from_position(current.clone(), EnPassantMode::Legal).to_string();
    let mut moves = movements
        .into_iter()
        .filter_map(|movement| {
            let uci = movement.to_uci(CastlingMode::Standard).to_string();
            let next = current.clone().play(&movement).ok()?;
            let preferred_score = preferred.is_some_and(|best| best == uci);
            let tactical = is_tactical_fen(&fen, &uci);
            let history_score = history
                .and_then(|scores| move_squares(&uci).map(|(from, to)| scores[from][to]))
                .unwrap_or_default();
            Some((
                uci,
                movement,
                preferred_score,
                tactical,
                history_score,
                -evaluate(&next),
            ))
        })
        .collect::<Vec<_>>();
    moves.sort_by(|left, right| {
        right
            .2
            .cmp(&left.2)
            .then_with(|| right.3.cmp(&left.3))
            .then_with(|| right.4.cmp(&left.4))
            .then_with(|| right.5.cmp(&left.5))
            .then_with(|| left.0.cmp(&right.0))
    });
    moves
        .into_iter()
        .map(|(uci, movement, _, _, _, _)| (uci, movement))
        .collect()
}

fn is_tactical(current: &Position, uci: &str) -> bool {
    is_tactical_fen(
        &Fen::from_position(current.clone(), EnPassantMode::Legal).to_string(),
        uci,
    )
}

fn is_tactical_fen(fen: &str, uci: &str) -> bool {
    if uci.len() == 5 {
        return true;
    }
    let (from, to) = (&uci[..2], &uci[2..4]);
    piece_at(fen, to).is_some()
        || matches!(piece_at(fen, from), Some('P' | 'p')) && from.as_bytes()[0] != to.as_bytes()[0]
}

fn move_squares(uci: &str) -> Option<(usize, usize)> {
    if uci.len() < 4 {
        return None;
    }
    Some((
        square_index(uci.get(..2)?.as_bytes())?,
        square_index(uci.get(2..4)?.as_bytes())?,
    ))
}

fn square_index(bytes: &[u8]) -> Option<usize> {
    let [file, rank] = *bytes else {
        return None;
    };
    if !matches!(file, b'a'..=b'h') || !matches!(rank, b'1'..=b'8') {
        return None;
    }
    Some(usize::from(rank - b'1') * 8 + usize::from(file - b'a'))
}

fn search_key(current: &Position) -> u64 {
    // FNV-1a makes the index deterministic across runs. Include the halfmove
    // clock, because it changes the fifty-move-rule outcome.
    Fen::from_position(current.clone(), EnPassantMode::Legal)
        .to_string()
        .bytes()
        .fold(0xcbf2_9ce4_8422_2325_u64, |hash, byte| {
            (hash ^ u64::from(byte)).wrapping_mul(0x0000_0100_0000_01b3)
        })
}

fn evaluate(current: &Position) -> i32 {
    let fen = Fen::from_position(current.clone(), EnPassantMode::Legal).to_string();
    let mut score = 0;
    let mut rank = 0_i32;
    let mut file = 0_i32;
    for character in fen.split_whitespace().next().unwrap_or_default().chars() {
        if character == '/' {
            rank += 1;
            file = 0;
        } else if let Some(empty) = character.to_digit(10) {
            file += i32::try_from(empty).unwrap_or_default();
        } else {
            let center = 14 - ((file * 2 - 7).abs() + (rank * 2 - 7).abs());
            let white = character.is_ascii_uppercase();
            let advancement = if white { 6 - rank } else { rank - 1 }.max(0);
            let value = match character.to_ascii_lowercase() {
                'p' => 100 + advancement * 8 + center * 2,
                'n' => 320 + center * 8,
                'b' => 330 + center * 4,
                'r' => 500 + center,
                'q' => 900 + center,
                _ => 0,
            };
            score += if white { value } else { -value };
            file += 1;
        }
    }
    let mobility = i32::try_from(current.legal_moves().len()).unwrap_or_default() * 2;
    match fen.split_whitespace().nth(1) {
        Some("w") => score + mobility,
        Some("b") => -score + mobility,
        _ => 0,
    }
}
