const stats = @import("stats");

pub const KeyEvent = struct {
    timestamp: u32,
    key_code: stats.UsbHidKey,
    //scan_code: u32,
    //flags: u32,
};

pub const KeyboardHook = struct {
    callback: *const fn (KeyEvent, *stats.TypingStats) void,
    platform_data: usize,
};