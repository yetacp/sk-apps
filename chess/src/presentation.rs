//! Mapping from chess domain state and semantic controls to StartK UI documents.

use crate::{Action, ChessApp, GameView};
use startk_ui::{Alignment, Document, DocumentError, Node};

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

fn move_history_lines(rounds: &[(usize, String, Option<String>)]) -> Vec<String> {
    rounds
        .chunks(2)
        .map(|line| {
            line.iter()
                .map(|(number, white, black)| match black {
                    Some(black) => format!("{number}. {white} ... {black}"),
                    None => format!("{number}. {white}"),
                })
                .collect::<Vec<_>>()
                .join("    ")
        })
        .collect()
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
    let toolbar = Node::row_with_layout(
        vec![
            icon_button("undo", "arrow-counter-clockwise"),
            icon_button("new-game", "arrow-clockwise"),
            icon_button(
                "opponent",
                if view.opponent == "Two players" {
                    "person"
                } else {
                    "robot"
                },
            ),
            icon_button("difficulty", "brain"),
            icon_button("orientation", "arrows-left-right"),
            icon_button("draw", "handshake"),
            icon_button("resign", "flag-checkered"),
        ],
        0,
        16,
        Alignment::Center,
    );
    let mut move_rows = vec![Node::text("Moves".to_owned())];
    let move_lines = move_history_lines(&view.recent_rounds);
    if move_lines.is_empty() {
        move_rows.push(Node::text("No moves yet".to_owned()));
    } else {
        move_rows.extend(move_lines.into_iter().map(Node::text));
    }
    let moves = Node::column_with_layout(move_rows, 0, 4, Alignment::Center);
    let board = Node::chess_board(
        "board".to_owned(),
        board,
        marks.into_iter().collect(),
        selected,
        view.flipped,
    );
    let status = format!(
        "{}. {}",
        view.status,
        view.notice.unwrap_or_else(|| view.opponent.to_owned())
    );
    let mut children = vec![
        Node::title_bar(
            "Chess".to_owned(),
            Some(("close".to_owned(), Some("arrow-left".to_owned()), None)),
            Vec::new(),
        ),
        toolbar,
        Node::text(status),
        board,
        Node::space(0, 24),
        moves,
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
        children.push(Node::dialog(
            title.to_owned(),
            message.to_owned(),
            vec![
                ("cancel-result".to_owned(), "Keep playing".to_owned()),
                ("confirm-result".to_owned(), "Confirm".to_owned()),
            ],
            true,
        ));
    }
    Node::form(
        "chess".to_owned(),
        Vec::new(),
        Node::column_with_layout(children, 0, 8, Alignment::Center),
    )
}

fn icon_button(id: &str, icon: &str) -> Node {
    Node::icon_button(id.to_owned(), icon.to_owned(), None, true)
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn initial_chess_document_is_valid() {
        let document = ChessApp::new().document().expect("initial document");
        Document::decode(&document.encode()).expect("encoded document remains valid");
        startk_ui::Layout::compute(&document).expect("initial document fits the logical canvas");
    }

    #[test]
    fn board_and_recent_move_grid_fit_after_moves() {
        let mut app = ChessApp::new();
        for control in [
            "board.e2", "board.e4", "board.e7", "board.e5", "board.g1", "board.f3", "board.b8",
            "board.c6",
        ] {
            assert_eq!(app.activate(control), ControlResult::Updated);
        }

        let document = app.document().expect("game document");
        startk_ui::Layout::compute(&document).expect("board and move history fit the canvas");
        assert_eq!(
            app.view().recent_rounds[0],
            (2, "Nf3".to_owned(), Some("Nc6".to_owned()))
        );
    }

    #[test]
    fn move_number_digits_do_not_shift_the_centered_board() {
        let layout_for_move = |number| {
            let view = GameView {
                squares: [None; 64],
                selected: None,
                destinations: Vec::new(),
                flipped: false,
                status: "White to move".to_owned(),
                notice: None,
                recent_rounds: vec![(number, "e4".to_owned(), Some("e5".to_owned()))],
                outcome: None,
                opponent: "Kobo plays Black",
                difficulty: "Easy",
                promotion_choices: Vec::new(),
                confirmation: None,
            };
            let document = Document::new(screen(view)).expect("valid document");
            startk_ui::Layout::compute(&document).expect("fitting document")
        };

        let one_digit = layout_for_move(1)
            .hit_bounds(536, 300)
            .expect("board square");
        let two_digits = layout_for_move(10)
            .hit_bounds(536, 300)
            .expect("board square");
        let three_digits = layout_for_move(100)
            .hit_bounds(536, 300)
            .expect("board square");
        assert_eq!(one_digit, two_digits);
        assert_eq!(two_digits, three_digits);
    }
    #[test]
    fn move_history_puts_white_before_black_and_newest_round_first() {
        let rounds = vec![
            (2, "Nc3".to_owned(), Some("Nf6".to_owned())),
            (1, "e4".to_owned(), Some("Nc6".to_owned())),
        ];

        assert_eq!(
            move_history_lines(&rounds),
            vec!["2. Nc3 ... Nf6    1. e4 ... Nc6"]
        );
    }

    #[test]
    fn unfinished_round_shows_the_white_move_only() {
        let rounds = vec![(3, "Bb5".to_owned(), None)];

        assert_eq!(move_history_lines(&rounds), vec!["3. Bb5"]);
    }
}
