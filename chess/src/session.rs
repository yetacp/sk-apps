//! Session loop for the native Chess client. All persistence uses the daemon
//! broker and all presentation is sent as a validated StartK document.

use std::{
    fmt::Display,
    io::{Read, Write},
    time::Duration,
};

use rmpv::Value;
use startk_app_client::{Client, ClientEvent};

use crate::{ChessApp, ControlResult};

const SAVE_PATH: &str = "chess.sav";

/// Runs Chess over an already-handshaken StartK session client.
pub fn run<S: Read + Write>(mut client: Client<S>) -> Result<(), String> {
    client
        .send_ipc(startk_ipc::sprites::select_event("chess.sprites.json").map_err(show)?)
        .map_err(show)?;

    let load_id = client
        .request_service(
            "file.read".to_owned(),
            path_payload(),
            Duration::from_secs(5),
        )
        .map_err(show)?;
    let mut app = ChessApp::new();
    loop {
        match client.next_event().map_err(show)? {
            ClientEvent::ServiceResult { id, result } if id == load_id => {
                if let Ok(Value::Binary(bytes)) = result
                    && let Ok(record) = std::str::from_utf8(&bytes)
                {
                    let _ = app.restore(record);
                }
                break;
            }
            ClientEvent::Exit(_) => return Ok(()),
            ClientEvent::IpcEvent(_) | ClientEvent::IpcRequest(_) | ClientEvent::IpcCancel(_) => {}
            ClientEvent::Action(_) | ClientEvent::ServiceResult { .. } => {}
        }
    }

    client
        .publish(&app.document().map_err(show)?)
        .map_err(show)?;
    client.ready().map_err(show)?;

    let mut pending_save = None;
    loop {
        match client.next_event().map_err(show)? {
            ClientEvent::Action(action) => {
                if app.activate(action.control_id()) == ControlResult::Exit {
                    client.exit().map_err(show)?;
                    return Ok(());
                }
                client
                    .publish(&app.document().map_err(show)?)
                    .map_err(show)?;
                let bytes = app.save().into_bytes();
                let id = client
                    .request_service(
                        "file.write".to_owned(),
                        Value::Map(vec![
                            (Value::from("path"), Value::from(SAVE_PATH)),
                            (Value::from("content"), Value::Binary(bytes)),
                        ]),
                        Duration::from_secs(5),
                    )
                    .map_err(show)?;
                pending_save = Some(id);
            }
            ClientEvent::ServiceResult { id, result } if pending_save == Some(id) => {
                pending_save = None;
                if let Err(error) = result {
                    let _ = client.log(
                        startk_protocol::message::LogLevel::Warn,
                        format!("Chess save failed: {error}"),
                    );
                }
                client.ready().map_err(show)?;
            }
            ClientEvent::ServiceResult { .. }
            | ClientEvent::IpcEvent(_)
            | ClientEvent::IpcRequest(_)
            | ClientEvent::IpcCancel(_) => {}
            ClientEvent::Exit(_) => return Ok(()),
        }
    }
}

fn path_payload() -> Value {
    Value::Map(vec![(Value::from("path"), Value::from(SAVE_PATH))])
}

fn show(error: impl Display) -> String {
    error.to_string()
}
