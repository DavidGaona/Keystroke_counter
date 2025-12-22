const std = @import("std");
pub const UsbHidKey = @import("types.zig").UsbHidKey;
pub const db = @import("db.zig");
const c = db.c;

/// Holds the data
pub const TypingStats = struct {
    db: *c.sqlite3,
    unigrams: [0xE8]u32, // Note: 0xE7(231) + 1 is the last number in UsbHidKey we + 1 as 0 is included

    bigrams: [0xE8][0xE8]u32,
    bigram_time_buffer: [1024]BigramTime,
    bigram_time_buffer_idx: usize,

    shortcut_buffer: [64]Shortcut,
    shortcut_buffer_idx: usize,

    prev_time: u32,
    prev_key: UsbHidKey,

    pub fn init() !TypingStats {
        const dbi = try db.initDatabase("typing_stats.db");

        var typingStats = TypingStats{
            .db = dbi,
            .unigrams = [_]u32{0} ** 0xE8,
            .bigrams = [_][0xE8]u32{[_]u32{0} ** 0xE8} ** 0xE8,
            .bigram_time_buffer = undefined,
            .bigram_time_buffer_idx = 0,
            .shortcut_buffer = undefined,
            .shortcut_buffer_idx = 0,
            .prev_time = 0,
            .prev_key = .None,
        };

        try db.loadUnigramFrequencies(&typingStats);
        try db.loadBigramFrequencies(&typingStats);

        return typingStats;
    }

    pub fn recordKeyStroke(
        self: *TypingStats,
        time: u32,
        key: UsbHidKey
    ) !void {
        self.unigrams[@intCast(@intFromEnum(key))] += 1;

        self.bigrams[@intCast(@intFromEnum(self.prev_key))][@intCast(@intFromEnum(key))] += 1;
        self.bigram_time_buffer[self.bigram_time_buffer_idx] = BigramTime{
            .time = time - self.prev_time,
            .first = self.prev_key,
            .second = key,
        };
        self.bigram_time_buffer_idx += 1;

        if (self.bigram_time_buffer_idx == self.bigram_time_buffer.len) {
            std.debug.print("Current idx {d}\n", .{self.bigram_time_buffer_idx});
            try self.saveBigramBuffer();
            self.bigram_time_buffer_idx = 0;
        }

        self.prev_time = time;
        self.prev_key = key;
    }

    pub fn recordShortcut(
        self: *TypingStats,
        time_delta: u32,
        control_keys: ControlKeys,
        key: UsbHidKey
    ) !void {
        self.shortcut_buffer[self.shortcut_buffer_idx] = Shortcut{
            .time = time_delta,
            .key = key,
            .control_keys = control_keys
        };
        self.shortcut_buffer_idx += 1;

        if (self.shortcut_buffer_idx == self.shortcut_buffer.len) {
            try self.saveShortcutBuffer();
            self.shortcut_buffer_idx = 0;
        }
    }

    pub fn saveBigramBuffer(self: TypingStats) !void {
        db.saveBigrams(self) catch |err| switch (err) {
            else => {std.debug.print("{}\n", .{err});},
            // ToDo implement logs and fallback mechanisms
        };
    }

    pub fn saveShortcutBuffer(self: TypingStats) !void {
        db.saveShortcuts(self) catch |err| switch (err) {
            else => {std.debug.print("{}\n", .{err});},
            // ToDo implement logs and fallback mechanisms
        };
    }

    pub fn saveAll(self: *TypingStats) void {
        db.saveAll(self) catch |err| switch (err) {
            else => {std.debug.print("{}\n", .{err});},
            // ToDo implement logs and fallback mechanisms
        };
    }

    pub fn saveAndResetAll(self: *TypingStats) !void {
        db.saveAll(self) catch |err| switch (err) {
            else => {std.debug.print("{}\n", .{err});},
            // ToDo implement logs and fallback mechanisms
        };
        // @memset(&self.unigrams, 0);
        // const flat_bigrams: *[256 * 256]u32 = @ptrCast(&self.bigrams);
        // @memset(flat_bigrams, 0);
        self.bigram_time_buffer_idx = 0;
        self.shortcut_buffer_idx = 0;
    }

    pub fn print(self: TypingStats) void {
        std.debug.print("\nBigrams\n", .{});
        for (0..self.bigram_time_buffer_idx) |i| {
            std.debug.print("First: 0x{x}, Second: 0x{x}\n", .{
                self.bigram_time_buffer[i].first,
                self.bigram_time_buffer[i].second
            });
            const first = UsbHidKey.getName(self.bigram_time_buffer[i].first);
            const second = UsbHidKey.getName(self.bigram_time_buffer[i].second);
            const time = self.bigram_time_buffer[i].time;
            std.debug.print("{s}, {s}, {d}\n", .{first, second, time});
        }

        std.debug.print("\nControl Keys\n", .{});
        for (0..self.shortcut_buffer_idx) |i| {
            const key = UsbHidKey.getName(self.shortcut_buffer[i].key);
            const time = self.shortcut_buffer[i].time;
            const control_keys: u8 = @bitCast(self.shortcut_buffer[i].control_keys);
            std.debug.print("{s}, {d}, {b:0>8}\n", .{key, time, control_keys});
        }
    }

};

// Used to track control key sequences like alt + tab, ctrl + c, etc.
// Also tracks the time it took to type that sequence in millis
pub const Shortcut = struct {
    time: u32,
    key: UsbHidKey,
    control_keys: ControlKeys,
};

// Track the time taken between 2 key strokes in millis
pub const BigramTime = struct {
    time: u32,
    first: UsbHidKey,
    second: UsbHidKey,
};

// Bitfield to show which ctrl keys are active
pub const ControlKeys = packed struct {
    LeftCtrl: u1,
    LeftShift: u1,
    LeftAlt: u1,
    LeftGui: u1,
    RightCtrl: u1,
    RightShift: u1,
    RightAlt: u1,
    RightGui: u1,

    /// Check if any modifier key is pressed
    pub fn isAnyPressed(self: ControlKeys) bool {
        return @as(u8, @bitCast(self)) != 0;
    }

    /// Check if no modifier keys are pressed
    pub fn isNonePressed(self: ControlKeys) bool {
        return @as(u8, @bitCast(self)) == 0;
    }
};
