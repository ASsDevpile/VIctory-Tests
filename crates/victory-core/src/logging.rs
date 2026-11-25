//! One tracing setup for every binary.
//!
//! Filter with `VICTORY_LOG` (falls back to `RUST_LOG`), e.g.
//! `VICTORY_LOG=victory_loader=trace,info`. Debug and trace output exist
//! only in builds with the `diagnostics` feature; a plain release build
//! logs info and above whatever the filter asks for.
//!
//! `run`'s `--log` writes the same lines to a file as they reach the
//! console: the launcher keeps them all without redirection (`*>`).

use std::sync::Mutex;

use tracing_subscriber::EnvFilter;
use tracing_subscriber::filter::LevelFilter;
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;

/// The most verbose level this build can log.
const CAP: LevelFilter = if cfg!(feature = "diagnostics") {
    LevelFilter::TRACE
} else {
    LevelFilter::INFO
};

/// With `log` (a file opened to append), a layer writing there shares the
/// console's filter; a file that cannot be opened is not fatal: it is the
/// launch's report that matters, not the log. Which file backs the log,
/// `victory run` prints itself.
pub fn init(default_level: &str, log: Option<&std::path::Path>) {
    let filter = std::env::var("VICTORY_LOG")
        .or_else(|_| std::env::var("RUST_LOG"))
        .ok()
        .and_then(|v| EnvFilter::try_new(v).ok())
        .unwrap_or_else(|| EnvFilter::new(default_level));
    let registry = tracing_subscriber::registry().with(CAP).with(filter);
    let console = tracing_subscriber::fmt::layer()
        .with_target(true)
        .with_writer(std::io::stderr);
    let file = log.and_then(|p| {
        std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(p)
            .inspect_err(|e| eprintln!("cannot write the log {}: {e}", p.display()))
            .ok()
            .map(Mutex::new)
    });
    let _ = match file {
        // The file outlives every logged line; one process writes it.
        Some(file) => registry
            .with(console)
            .with(
                tracing_subscriber::fmt::layer()
                    .with_target(true)
                    .with_ansi(false)
                    .with_writer(file),
            )
            .try_init(),
        None => registry.with(console).try_init(),
    };
}
