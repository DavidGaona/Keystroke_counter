const std = @import("std");
const builtin = @import("builtin");

const stats = @import("stats");
const win32 = @import("win32.zig");
const linux = @import("linux.zig");
pub const types = @import("types.zig");

pub fn install(
    hook_func: *const fn (types.KeyEvent, *stats.TypingStats) void,
    key_log_stats: *stats.TypingStats
) !types.KeyboardHook {
    return switch (builtin.os.tag) {
        .windows => try win32.install(hook_func, key_log_stats),
        .linux => {},
        .macos => {},
        else => error.PlatformNotSupported
    };
}

pub fn uninstall(keyboard_hook: *types.KeyboardHook) void {
    switch (builtin.os.tag) {
        .windows => win32.uninstall(keyboard_hook),
        .linux => {},
        .macos => {},
        else => {},
    }
}

pub fn pollEvents() void {
    switch (builtin.os.tag) {
        .windows => win32.pollEvents(),
        .linux => {},
        else => {},
    }
}
