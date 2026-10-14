#![deny(unsafe_code)]

use std::{
    os::{
        fd::{FromRawFd, OwnedFd},
        unix::net::UnixStream,
    },
    process::ExitCode,
};

use startk_app_client::Client;
use startk_chess_core::run_session;
use startk_protocol::{SessionId, SessionNonce, message::LogLevel};

const SESSION_FD: i32 = 3;

fn run() -> Result<(), String> {
    let session = std::env::var("STARTK_SESSION_ID")
        .map_err(|_| "missing StartK session identity".to_owned())?
        .parse::<u64>()
        .map_err(|_| "invalid StartK session identity".to_owned())
        .and_then(|id| SessionId::new(id).map_err(|error| error.to_string()))?;
    let nonce = std::env::var("STARTK_SESSION_NONCE")
        .map_err(|_| "missing StartK session nonce".to_owned())
        .and_then(|value| SessionNonce::from_hex(&value).map_err(|error| error.to_string()))?;

    let stream = UnixStream::from(session_stream());
    let mut client = Client::connect(stream, session, nonce).map_err(|error| error.to_string())?;
    client
        .log(
            LogLevel::Info,
            format!(
                "Chess version={} build_unix={}",
                env!("CARGO_PKG_VERSION"),
                env!("STARTK_BUILD_UNIX")
            ),
        )
        .map_err(|error| error.to_string())?;
    run_session(client)
}

/// Takes ownership of fd 3, which the StartK supervisor must provide as the
/// connected session socket for a Rust app.
#[allow(unsafe_code)]
fn session_stream() -> OwnedFd {
    // SAFETY: the Rust launch contract assigns fd 3 to this session socket and
    // transfers its ownership to the child before the app starts.
    unsafe { OwnedFd::from_raw_fd(SESSION_FD) }
}

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("Chess startup/session error: {error}");
            ExitCode::FAILURE
        }
    }
}
