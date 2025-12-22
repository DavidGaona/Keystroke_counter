const std = @import("std");
const types = @import("types.zig");
const TypingStats = @import("stats.zig").TypingStats;
pub const c = @cImport({
    @cInclude("sqlite3.h");
});

pub fn initDatabase(db_path: []const u8) !*c.sqlite3 {
    var db: ?*c.sqlite3 = null;
    var rc = c.sqlite3_open(db_path.ptr, &db);
    if (rc != c.SQLITE_OK) {
        return error.SQLiteError;
    }

    const schema =
        \\CREATE TABLE IF NOT EXISTS unigrams_freq (
        \\    key_id INTEGER PRIMARY KEY NOT NULL,
        \\    frequency INTEGER NOT NULL
        \\) WITHOUT ROWID;
        \\CREATE TABLE IF NOT EXISTS bigrams_freq (
        \\    first_key INTEGER NOT NULL,
        \\    second_key INTEGER NOT NULL,
        \\    frequency INTEGER NOT NULL,
        \\    PRIMARY KEY (first_key, second_key)
        \\) WITHOUT ROWID;
        \\CREATE TABLE IF NOT EXISTS bigrams (
        \\    time INTEGER NOT NULL,
        \\    first INTEGER NOT NULL,
        \\    SECOND INTEGER NOT NULL
        \\);
        \\CREATE TABLE IF NOT EXISTS shortcuts (
        \\    time INTEGER NOT NULL,
        \\    key INTEGER NOT NULL,
        \\    control_keys INTEGER NOT NULL
        \\);
    ;

    var err_msg: [*c]u8 = null;
    rc = c.sqlite3_exec(db, schema, null, null, &err_msg);
    if (rc != c.SQLITE_OK) {
        std.debug.print("Schema creation error: {s}\n", .{err_msg});
        c.sqlite3_free(err_msg);
        return error.SQLiteError;
    }

    try initUnigramsFreq(db.?);
    try initBigramsFreq(db.?);

    return db.?;
}

fn initUnigramsFreq(db: *c.sqlite3) !void {
    var count_stmt: ?*c.sqlite3_stmt = null;
    try prepare_v2(db, "SELECT COUNT(*) FROM unigrams_freq;", -1, &count_stmt, null);
    defer _ = c.sqlite3_finalize(count_stmt);
    if (try step_row(count_stmt, db)) {
        const row_count = c.sqlite3_column_int(count_stmt, 0);
        if (row_count > 0) return;
    }

    try begin_transaction(db);
    errdefer _ = rollback(db);
    var unigrams_stmt: ?*c.sqlite3_stmt = null;
    try prepare_v2(db, "INSERT INTO unigrams_freq VALUES (?, ?);", -1, &unigrams_stmt, null);
    defer _ = c.sqlite3_finalize(unigrams_stmt);

    var key_id: u8 = 0;
    while (key_id <= 0xE7) : (key_id += 1) {
        _ = std.meta.intToEnum(types.UsbHidKey, key_id) catch continue;
        try bind_int(unigrams_stmt, 1, key_id, db);
        try bind_int(unigrams_stmt, 2, @as(u32, 0), db);
        try step(unigrams_stmt, db);
        _ = c.sqlite3_reset(unigrams_stmt);
    }
    try commit(db);
}

fn initBigramsFreq(db: *c.sqlite3) !void {
    var count_stmt: ?*c.sqlite3_stmt = null;
    try prepare_v2(db, "SELECT COUNT(*) FROM bigrams_freq;", -1, &count_stmt, null);
    defer _ = c.sqlite3_finalize(count_stmt);
    if (try step_row(count_stmt, db)) {
        const row_count = c.sqlite3_column_int(count_stmt, 0);
        if (row_count > 0) return;
    }

    try begin_transaction(db);
    errdefer _ = rollback(db);
    var bigrams_stmt: ?*c.sqlite3_stmt = null;
    try prepare_v2(db, "INSERT INTO bigrams_freq VALUES (?, ?, ?);", -1, &bigrams_stmt, null);
    defer _ = c.sqlite3_finalize(bigrams_stmt);

    var first_key: u8 = 0;
    while (first_key <= 0xE7) : (first_key += 1) {
        _ = std.meta.intToEnum(types.UsbHidKey, first_key) catch continue;
        var second_key: u8 = 0;
        while (second_key <= 0xE7) : (second_key += 1) {
            _ = std.meta.intToEnum(types.UsbHidKey, first_key) catch continue;
            try bind_int(bigrams_stmt, 1, first_key, db);
            try bind_int(bigrams_stmt, 2, second_key, db);
            try bind_int(bigrams_stmt, 3, @as(u32, 0), db);
            try step(bigrams_stmt, db);
            _ = c.sqlite3_reset(bigrams_stmt);
        }
    }
    try commit(db);
}

pub fn saveAll(stats: *const TypingStats) !void {
    const db = stats.db;
    try begin_transaction(db);
    errdefer _ = rollback(db);

    var unigrams_freq_stmt: ?*c.sqlite3_stmt = null;
    try prepare_v2(db, "UPDATE unigrams_freq SET frequency = ? WHERE key_id = ?;", -1, &unigrams_freq_stmt, null);
    defer _ = c.sqlite3_finalize(unigrams_freq_stmt);

    for (stats.unigrams, 0..) |freq, key| {
        if (freq > 0) {
            try bind_int(unigrams_freq_stmt, 1, @intCast(freq), db);
            try bind_int(unigrams_freq_stmt, 2, @as(u8, @intCast(key)), db);
            try step(unigrams_freq_stmt, db);
            _ = c.sqlite3_reset(unigrams_freq_stmt);
        }
    }

    var bigrams_freq_stmt: ?*c.sqlite3_stmt = null;
    try prepare_v2(db,
        "UPDATE bigrams_freq SET frequency = ? WHERE first_key = ? AND second_key = ?;",
        -1, &bigrams_freq_stmt, null
    );
    defer _ = c.sqlite3_finalize(bigrams_freq_stmt);
    for (0..0xE7) |i| {
        for (0..0xE7) |j| {
            if (stats.bigrams[i][j] > 0) {
                try bind_int(bigrams_freq_stmt, 1, @intCast(stats.bigrams[i][j]), db);
                try bind_int(bigrams_freq_stmt, 2, @as(u8, @intCast(i)), db);
                try bind_int(bigrams_freq_stmt, 3, @as(u8, @intCast(j)), db);
                try step(bigrams_freq_stmt, db);
                _ = c.sqlite3_reset(bigrams_freq_stmt);
            }
        }
    }

    var bigrams_stmt: ?* c.sqlite3_stmt = null;
    try prepare_v2(db, "INSERT INTO bigrams VALUES (?, ?, ?)", -1, &bigrams_stmt, null);
    defer _ = c.sqlite3_finalize(bigrams_stmt);
    
    for (stats.bigram_time_buffer[0..stats.bigram_time_buffer_idx]) |bigram| {
        try bind_int(bigrams_stmt, 1, @intCast(bigram.time), db);
        try bind_int(bigrams_stmt, 2, @intCast(@intFromEnum(bigram.first)), db);
        try bind_int(bigrams_stmt, 3, @intCast(@intFromEnum(bigram.second)), db);
        try step(bigrams_stmt, db);
        _ = c.sqlite3_reset(bigrams_stmt);
    }

    var shortcut_stmt: ?* c.sqlite3_stmt = null;
    try prepare_v2(db, "INSERT INTO shortcuts VALUES (?, ?, ?)", -1, &shortcut_stmt, null);
    defer _ = c.sqlite3_finalize(shortcut_stmt);

    for (stats.shortcut_buffer[0..stats.shortcut_buffer_idx]) |shortcut| {
        try bind_int(shortcut_stmt, 1, @intCast(shortcut.time), db);
        try bind_int(shortcut_stmt, 2, @intCast(@intFromEnum(shortcut.key)), db);
        try bind_int(shortcut_stmt, 3, @intCast(@as(u8, @bitCast(shortcut.control_keys))), db);
        try step(shortcut_stmt, db);
        _ = c.sqlite3_reset(shortcut_stmt);
    }

    try commit(db);

}

pub fn saveBigrams(stats: TypingStats) !void {
    const db = stats.db;
    try begin_transaction(db);
    errdefer _ = rollback(db);

    var bigrams_stmt: ?* c.sqlite3_stmt = null;
    try prepare_v2(db, "INSERT INTO bigrams VALUES (?, ?, ?)", -1, &bigrams_stmt, null);
    defer _ = c.sqlite3_finalize(bigrams_stmt);

    for (stats.bigram_time_buffer, 0..stats.bigram_time_buffer_idx) |bigram, _| {
        try bind_int(bigrams_stmt, 1, @intCast(bigram.time), db);
        try bind_int(bigrams_stmt, 2, @intCast(@intFromEnum(bigram.first)), db);
        try bind_int(bigrams_stmt, 3, @intCast(@intFromEnum(bigram.second)), db);
        try step(bigrams_stmt, db);
    }

    try commit(db);
}

pub fn saveShortcuts(stats: TypingStats) !void {
    const db = stats.db;
    try begin_transaction(db);
    errdefer _ = rollback(db);

    var shortcut_stmt: ?* c.sqlite3_stmt = null;
    try prepare_v2(db, "INSERT INTO shortcuts VALUES (?, ?, ?)", -1, &shortcut_stmt, null);
    defer _ = c.sqlite3_finalize(shortcut_stmt);

    for (stats.shortcut_buffer, 0..stats.shortcut_buffer_idx) |shortcut, _| {
        try bind_int(shortcut_stmt, 1, @intCast(shortcut.time), db);
        try bind_int(shortcut_stmt, 2, @intCast(@intFromEnum(shortcut.key)), db);
        try bind_int(shortcut_stmt, 3, @intCast(@as(u8, @bitCast(shortcut.control_keys))), db);
        try step(shortcut_stmt, db);
    }

    try commit(db);
}

pub fn closeDatabase(db: *c.sqlite3, stats: TypingStats) void {
    saveAll(db, stats);
    c.sqlite3_close(db);
}

pub fn loadUnigramFrequencies(stats: *TypingStats) !void {
    const query = "SELECT * FROM unigrams_freq WHERE frequency > 0;";
    var stmt: ?*c.sqlite3_stmt = null;
    try prepare_v2(stats.db, query, -1, &stmt, null);
    defer _ = c.sqlite3_finalize(stmt);
    while (try step_row(stmt, stats.db)) {
        const key_code: usize = @intCast(c.sqlite3_column_int(stmt, 0));
        const frequency: u32 = @intCast(c.sqlite3_column_int(stmt, 1));
        stats.unigrams[key_code] = frequency;
    }
}

pub fn loadBigramFrequencies(stats: *TypingStats) !void {
    const query = "SELECT * FROM bigrams_freq WHERE frequency > 0;";
    var stmt: ?*c.sqlite3_stmt = null;
    try prepare_v2(stats.db, query, -1, &stmt, null);
    defer _ = c.sqlite3_finalize(stmt);
    while (try step_row(stmt, stats.db)) {
        const first_key: usize = @intCast(c.sqlite3_column_int(stmt, 0));
        const second_key: usize = @intCast(c.sqlite3_column_int(stmt, 1));
        const frequency: u32 = @intCast(c.sqlite3_column_int(stmt, 2));
        stats.bigrams[first_key][second_key] = frequency;
    }
}

// ================================== SQLite helper methods ==================================


/// Begins a new SQLite transaction.
/// Equivalent to: `sqlite3_exec(db, "BEGIN TRANSACTION", ...)`
///
/// Transactions group multiple operations into a single atomic unit,
/// dramatically improving performance for bulk inserts (100-1000x faster).
///
/// Parameters:
/// - `db`: Pointer to an open SQLite database connection
///
/// Returns:
/// - `error.SQLiteTransactionError` if the transaction could not be started
///
/// Usage:
/// ```zig
/// try begin_transaction(db);
/// errdefer rollback(db);
/// // ... perform operations ...
/// try commit(db);
/// ```
inline fn begin_transaction(db: *c.sqlite3) !void {
    const rc = c.sqlite3_exec(db, "BEGIN TRANSACTION", null, null, null);
    if (rc != c.SQLITE_OK) {
        std.debug.print("[SQLite] BEGIN TRANSACTION failed: code={} (0x{x:0>2}) - {s}\n",
            .{rc, rc, c.sqlite3_errmsg(db)});
        return error.SQLiteTransactionError;
    }
}

/// Commits the current SQLite transaction.
/// Equivalent to: `sqlite3_exec(db, "COMMIT", ...)`
///
/// Makes all changes since `begin_transaction()` permanent and visible
/// to other connections. If this fails, the transaction is automatically
/// rolled back by SQLite.
///
/// Parameters:
/// - `db`: Pointer to an open SQLite database connection
///
/// Returns:
/// - `error.SQLiteCommitError` if the commit failed
///
/// Note: Should be paired with `begin_transaction()` and an `errdefer rollback()`
inline fn commit(db: *c.sqlite3) !void {
    const rc = c.sqlite3_exec(db, "COMMIT", null, null, null);
    if (rc != c.SQLITE_OK) {
        std.debug.print(
            "[SQLITE] Commit failed: code={d}(0x{x:0>2}) - {s}",
            .{rc, rc, c.sqlite3_errmsg(db)}
        );
        return error.SQLiteCommitError;
    }
}

/// Rolls back the current SQLite transaction.
/// Equivalent to: `sqlite3_exec(db, "ROLLBACK", ...)`
///
/// Discards all changes since `begin_transaction()`. This function does not
/// return an error - rollback failures are ignored as they typically occur
/// when there's no active transaction.
///
/// Parameters:
/// - `db`: Pointer to an open SQLite database connection
///
/// Usage:
/// Typically used with `errdefer` to automatically rollback on errors:
/// ```zig
/// try begin_transaction(db);
/// errdefer rollback(db);
/// ```
inline fn rollback(db: *c.sqlite3) void {
    _ = c.sqlite3_exec(db, "ROLLBACK", null, null, null);
}

/// Binds an integer value to a prepared statement parameter.
/// Equivalent to: `sqlite3_bind_int(stmt, idx, val)`
///
/// Binds a 32-bit signed integer to a parameter placeholder (?) in a
/// prepared SQL statement. Parameters are 1-indexed.
///
/// Parameters:
/// - `stmt`: Prepared statement to bind to
/// - `idx`: Parameter index (1-based, not 0-based!)
/// - `val`: Integer value to bind (c_int / i32)
///
/// Returns:
/// - `error.SQLiteBindError` if binding failed
///
/// Example:
/// ```zig
/// const sql = "INSERT INTO table VALUES (?, ?)";
/// var stmt: ?*c.sqlite3_stmt = null;
/// try prepare_v2(db, sql, -1, &stmt, null);
/// try bind_int(stmt, 1, 42);  // First parameter
/// try bind_int(stmt, 2, 100); // Second parameter
/// try step(stmt);
/// ```
inline fn bind_int(stmt: ?*c.sqlite3_stmt, idx: c_int, val: c_int, db: *c.sqlite3) !void {
    const rc = c.sqlite3_bind_int(stmt, idx, val);
    if (rc != c.SQLITE_OK) {
        std.debug.print(
            "[SQLite] bind_int(idx={}, val={}) failed: code={} (0x{x:0>2}) - {s}\n",
            .{idx, val, rc, rc, c.sqlite3_errmsg(db)}
        );
        return error.SQLiteBindError;
    }
}

/// Binds a 64-bit integer value to a prepared statement parameter.
/// Equivalent to: `sqlite3_bind_int64(stmt, idx, val)`
///
/// Binds a 64-bit signed integer to a parameter placeholder (?) in a
/// prepared SQL statement. Use this for large integers or timestamps.
///
/// Parameters:
/// - `stmt`: Prepared statement to bind to
/// - `idx`: Parameter index (1-based, not 0-based!)
/// - `val`: 64-bit integer value to bind (i64)
///
/// Returns:
/// - `error.SQLiteBindError` if binding failed
///
/// Example:
/// ```zig
/// const timestamp = std.time.milliTimestamp(); // i64
/// try bind_int64(stmt, 1, timestamp);
/// ```
inline fn bind_int64(stmt: ?*c.sqlite3_stmt, idx: c_int, val: c_longlong, db: *c.sqlite3) !void {
    const rc = c.sqlite3_bind_int64(stmt, idx, val);
    if (rc != c.SQLITE_OK) {
        std.debug.print("[SQLite] bind_int64(idx={}, val={}) failed: code={} (0x{x:0>2}) - {s}\n",
            .{idx, val, rc, rc, c.sqlite3_errmsg(db)});
        return error.SQLiteBindError;
    }
}

/// Executes a prepared statement.
/// Equivalent to: `sqlite3_step(stmt)`
///
/// Executes the SQL statement with its bound parameters. For INSERT/UPDATE/DELETE,
/// this performs the operation. Must be called after binding all parameters.
/// Returns an error if the result is not SQLITE_DONE (for queries that modify data).
///
/// Parameters:
/// - `stmt`: Prepared statement to execute
///
/// Returns:
/// - `error.SQLiteStepError` if execution failed or result was not SQLITE_DONE
///
/// Note: After step() completes, call `sqlite3_reset()` to reuse the statement
/// with different bound values.
///
/// Example:
/// ```zig
/// for (items) |item| {
///     try bind_int(stmt, 1, item.value);
///     try step(stmt);                    // Execute INSERT
///     _ = c.sqlite3_reset(stmt);         // Reset for next iteration
/// }
/// ```
inline fn step(stmt: ?*c.sqlite3_stmt, db: *c.sqlite3) !void {
    const rc = c.sqlite3_step(stmt);
    if (rc != c.SQLITE_DONE) {
        std.debug.print("[SQLite] step failed: code={} (0x{x:0>2}) - {s}\n",
            .{rc, rc, c.sqlite3_errmsg(db)});
        return error.SQLiteStepError;
    }
}

inline fn step_row(stmt: ?*c.sqlite3_stmt, db: *c.sqlite3) !bool {
    const rc = c.sqlite3_step(stmt);
    if (rc == c.SQLITE_ROW) {
        return true;
    } else if (rc == c.SQLITE_DONE) {
        return false;
    } else {
        std.debug.print("[SQLite] step_row failed: code={} (0x{x:0>2}) - {s}\n",
            .{rc, rc, c.sqlite3_errmsg(db)});
        return error.SQLiteStepError;
    }
}

inline fn reset(stmt: ?*c.sqlite3_stmt, db: *c.sqlite3) !void {
    const rc = c.sqlite3_reset(stmt);
    if (rc != c.SQLITE_DONE) {
        std.debug.print("[SQLite] reset failed: code={} (0x{x:0>2}) - {s}\n",
            .{rc, rc, c.sqlite3_errmsg(db)});
        return error.SQLiteStepError;
    }
}



/// Prepares an SQL statement for execution.
/// Equivalent to: `sqlite3_prepare_v2(db, z_sql, n_byte, pp_stmt, pz_tail)`
///
/// Compiles an SQL statement into bytecode for efficient repeated execution.
/// The prepared statement should be finalized with `sqlite3_finalize()` when done.
///
/// Parameters:
/// - `db`: Pointer to an open SQLite database connection
/// - `z_sql`: SQL statement string (null-terminated)
/// - `n_byte`: Maximum length to read from z_sql, or -1 to read until null terminator
/// - `pp_stmt`: Output pointer to receive the prepared statement object
/// - `pz_tail`: Output pointer to unused portion of z_sql (usually null)
///
/// Returns:
/// - `error.SQLiteStmtError` if preparation failed (e.g., syntax error)
///
/// Example:
/// ```zig
/// var stmt: ?*c.sqlite3_stmt = null;
/// try prepare_v2(db, "INSERT INTO table VALUES (?)", -1, &stmt, null);
/// defer _ = c.sqlite3_finalize(stmt);
///
/// try bind_int(stmt, 1, 42);
/// try step(stmt);
/// ```
inline fn prepare_v2(
    db: ?*c.sqlite3,
    z_sql: [*c]const u8,
    n_byte: c_int,
    pp_stmt: [*c]?*c.sqlite3_stmt,
    pz_tail: [*c][*c]const u8
) !void {
    const rc = c.sqlite3_prepare_v2(db, z_sql, n_byte, pp_stmt, pz_tail);
    if (rc != c.SQLITE_OK) {
        std.debug.print("[SQLite] prepare failed: code={} (0x{x:0>2}) - {s}\n",
            .{rc, rc, c.sqlite3_errmsg(db)});
        std.debug.print("  SQL: {s}\n", .{z_sql});
        return error.SQLiteStmtError;
    }
}
