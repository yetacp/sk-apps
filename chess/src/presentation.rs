//! Mapping from chess domain state and semantic controls to StartK UI documents.

use crate::{Action, ChessApp, GameView};
use startk_ui::{Document, DocumentError, Node};

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ControlResult {
    Updated,
    Exit,
    Ignored,
}

impl ChessApp {
    /// Builds a validated declarative board document for `startkd`.
    pub fn document(&self) -> Result<Document, DocumentError> {
        let view = self.view();
        Document::new(screen(view))
    }

    /// Applies a semantic UI control ID. It never accepts board coordinates
    /// outside the canonical `board.<square>` form.
    pub fn activate(&mut self, control_id: &str) -> ControlResult {
        if control_id == "close" {
            return ControlResult::Exit;
        }
        let action = if let Some(square) = control_id.strip_prefix("board.") {
            if square_index(square).is_none() {
                return ControlResult::Ignored;
            }
            Action::Square(square.to_owned())
        } else if let Some(choice) = control_id.strip_prefix("promote-") {
            let mut chars = choice.chars();
            let Some(piece) = chars.next().filter(|_| chars.next().is_none()) else {
                return ControlResult::Ignored;
            };
            Action::Promote(piece)
        } else {
            match control_id {
                "undo" => Action::Undo,
                "new-game" => Action::NewGame,
                "opponent" => Action::ToggleOpponent,
                "difficulty" => Action::CycleDifficulty,
                "orientation" => Action::FlipBoard,
                "draw" => Action::AgreeDraw,
                "resign" => Action::Resign,
                "confirm-result" => Action::Confirm(true),
                "cancel-result" => Action::Confirm(false),
                _ => return ControlResult::Ignored,
            }
        };
        self.dispatch(action);
        ControlResult::Updated
    }
}

fn screen(view: GameView) -> Node {
    let board: String = view
        .squares
        .iter()
        .map(|piece| piece.unwrap_or('.'))
        .collect();
    let mut marks = ['0'; 64];
    for square in &view.destinations {
        if let Some(index) = square_index(square) {
            marks[usize::from(index)] = '1';
        }
    }
    let selected = view.selected.as_deref().and_then(square_index);
    let mut children = vec![
        Node::title_bar(
            "Chess".to_owned(),
            Some(("close".to_owned(), Some("arrow-left".to_owned()), None)),
            Vec::new(),
        ),
        Node::text(view.status),
        Node::text(view.notice.unwrap_or_else(|| {
            format!(
                "{} · Last move: {}",
                view.opponent,
                view.last_move.as_deref().unwrap_or("New game")
            )
        })),
        Node::chess_board(
            "board".to_owned(),
            board,
            marks.into_iter().collect(),
            selected,
            view.flipped,
        ),
        button_row([
            ("undo", "Undo"),
            ("new-game", "New game"),
            ("opponent", view.opponent),
        ]),
        button_row([
            ("difficulty", view.difficulty),
            ("orientation", "Flip board"),
            ("draw", "Agree draw"),
            ("resign", "Resign"),
        ]),
    ];

    if !view.promotion_choices.is_empty() {
        children.push(Node::text("Promote pawn to:".to_owned()));
        children.push(button_row(view.promotion_choices.iter().filter_map(
            |piece| {
                let label = match piece {
                    'q' => "Queen",
                    'r' => "Rook",
                    'b' => "Bishop",
                    'n' => "Knight",
                    _ => return None,
                };
                Some((
                    match piece {
                        'q' => "promote-q",
                        'r' => "promote-r",
                        'b' => "promote-b",
                        _ => "promote-n",
                    },
                    label,
                ))
            },
        )));
    }

    if let Some(outcome) = view.outcome {
        children.push(Node::text(outcome));
    }
    if let Some((title, message)) = view.confirmation {
        children.push(Node::confirm_box(
            title.to_owned(),
            message.to_owned(),
            "confirm-result".to_owned(),
            "cancel-result".to_owned(),
            "Confirm".to_owned(),
            "Keep playing".to_owned(),
        ));
    }
    Node::form(
        "chess".to_owned(),
        Vec::new(),
        Node::column_with_spacing(children, 16, 12),
    )
}

fn button_row(buttons: impl IntoIterator<Item = (&'static str, &'static str)>) -> Node {
    Node::row_with_spacing(
        buttons
            .into_iter()
            .map(|(id, label)| Node::button(id.to_owned(), label.to_owned()))
            .collect(),
        0,
        8,
    )
}

fn square_index(square: &str) -> Option<u8> {
    let bytes = square.as_bytes();
    if bytes.len() != 2 || !matches!(bytes[0], b'a'..=b'h') || !matches!(bytes[1], b'1'..=b'8') {
        return None;
    }
    Some((b'8' - bytes[1]) * 8 + bytes[0] - b'a')
}
