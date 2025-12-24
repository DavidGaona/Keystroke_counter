const std = @import("std");
const types = @import("types.zig");

const stats = @import("stats");
const win32 = @cImport({
    @cDefine("WIN32_LEAN_AND_MEAN", "1");
    @cInclude("windows.h");
});

const WindowCache = struct {
    hwnd: ?win32.HWND = null,
    process_id: u32,
    exe_name: [256]u8 = undefined,
    exe_name_len: usize = 0,
    window_title: [256]u8 = undefined,
    window_title_len: usize = 0,
};

const WinHooks = struct {
    keyboard_hook: win32.HHOOK,
    window_foreground_hook: win32.HWINEVENTHOOK
};

threadlocal var global_callback: ?*const fn (types.KeyEvent, *stats.TypingStats) void = null;
threadlocal var key_stats: ?*stats.TypingStats = null;
threadlocal var control_keys: stats.ControlKeys = @bitCast(@as(u8, 0));
threadlocal var control_keys_time = [_]u32{0} ** 8;
threadlocal var win_hooks: WinHooks = undefined;
threadlocal var window_cache: WindowCache = undefined;

fn hookProc(
    n_code: c_int,
    w_param: win32.WPARAM,
    l_param: win32.LPARAM
) callconv(.winapi) win32.LRESULT {
    // If nCode is less than zero, the hook procedure must return the value returned by CallNextHookEx.
    if (n_code < 0) return win32.CallNextHookEx(null, n_code, w_param, l_param);

    // ToDo handle software injected events

    // Read keys but not process them to allow the other apps to use those values
    if (w_param == win32.WM_KEYDOWN or w_param == win32.WM_SYSKEYDOWN) {
        const kbd = @as(*win32.KBDLLHOOKSTRUCT, @ptrFromInt(@as(usize, @intCast(l_param))));

        if (global_callback) |callback| {
            const code = vkToUsbHid(kbd.vkCode);
            std.debug.print("win:0x{x}, usb:0x{x}\n", .{kbd.vkCode, code});
            const event = types.KeyEvent{
                .timestamp = @intCast(kbd.time),
                .key_code = code,
                // .scan_code = kbd.scanCode,  // Hardware scan code
                //.flags = kbd.flags,          // Event flags
            };

            switch (kbd.vkCode) {
                win32.VK_CONTROL  => control_keys.LeftCtrl =   1,
                win32.VK_LCONTROL => control_keys.LeftCtrl =   1,
                win32.VK_RCONTROL => control_keys.RightCtrl =  1,
                win32.VK_SHIFT    => control_keys.LeftShift =  1,
                win32.VK_LSHIFT   => control_keys.LeftShift =  1,
                win32.VK_RSHIFT   => control_keys.RightShift = 1,
                win32.VK_MENU     => control_keys.LeftAlt =    1,
                win32.VK_LMENU    => control_keys.LeftAlt =    1,
                win32.VK_RMENU    => control_keys.RightAlt =   1,
                win32.VK_LWIN     => control_keys.LeftGui =    1,
                win32.VK_RWIN     => control_keys.RightGui =   1,
                else => {
                    if (control_keys.isAnyPressed()) {
                        var oldest_time: u32 = std.math.maxInt(u32);
                        inline for (0..8) |i| {
                            if (@as(u8, @bitCast(control_keys)) & (1 << @intCast(i)) > 0) {
                                oldest_time = @min(oldest_time, control_keys_time[i]);
                            }
                        }
                        try key_stats.?.recordShortcut(kbd.time - oldest_time, control_keys, code);
                    }
                }
            }
            const code_u8: u8 = @intFromEnum(code);
            // eqv to stats.UsbHidKey.LeftCtrl <= code <= stats.UsbHidKey.RightGui
            if (0xE0 <= code_u8 and code_u8 <= 0xE7) {
                control_keys_time[@intCast(code_u8 - 0xE0)] = @intCast(kbd.time);
            }

            callback(event, key_stats.?);
        }
    }

    if (w_param == win32.WM_KEYUP or w_param == win32.WM_SYSKEYUP) {
        const kbd = @as(*win32.KBDLLHOOKSTRUCT, @ptrFromInt(@as(usize, @intCast(l_param))));
        switch (kbd.vkCode) {
            win32.VK_CONTROL  => control_keys.LeftCtrl = 0,
            win32.VK_LCONTROL => control_keys.LeftCtrl = 0,
            win32.VK_RCONTROL => control_keys.RightCtrl = 0,
            win32.VK_SHIFT    => control_keys.LeftShift = 0,
            win32.VK_LSHIFT   => control_keys.LeftShift = 0,
            win32.VK_RSHIFT   => control_keys.RightShift = 0,
            win32.VK_MENU     => control_keys.LeftAlt = 0,
            win32.VK_LMENU    => control_keys.LeftAlt = 0,
            win32.VK_RMENU    => control_keys.RightAlt = 0,
            win32.VK_LWIN     => control_keys.LeftGui = 0,
            win32.VK_RWIN     => control_keys.RightGui = 0,
            else => {}
        }

    }

    // If nCode is greater than or equal to zero, and the hook procedure did not process the message,
    // it is highly recommended that you call CallNextHookEx and return the value it returns
    return win32.CallNextHookEx(null, n_code, w_param, l_param);
}

fn winEventProc(
    h_win_event_hook: win32.HWINEVENTHOOK,
    event: u32,
    hwnd: win32.HWND,
    id_object: i32,
    id_child: i32,
    id_event_thread: u32,
    dwms_event_time: u32
) callconv(.winapi) void {
    _ = dwms_event_time; // autofix
    _ = id_event_thread;
    _ = id_child; // autofix
    _ = id_object; // autofix
    _ = h_win_event_hook; // autofix
    if (event == win32.EVENT_SYSTEM_FOREGROUND) {
        window_cache.window_title_len = @intCast(win32.GetWindowTextA(
            hwnd,
            &window_cache.window_title,
            255,
        ));

        var process_id: u32 = 0;
        _ = win32.GetWindowThreadProcessId(hwnd, &process_id);

        const process_handle = win32.OpenProcess(
            win32.PROCESS_QUERY_LIMITED_INFORMATION,
            0,
            process_id,
        ) orelse return;
        defer _ = win32.CloseHandle(process_handle);

        var path_buffer: [win32.MAX_PATH]u8 = undefined;
        var path_size: u32 = win32.MAX_PATH;

        const success = win32.QueryFullProcessImageNameA(
            process_handle,
            0,
            &path_buffer,
            &path_size,
        );

        if (success != 0) {
            const full_path = path_buffer[0..path_size];
            const filename = std.fs.path.basename(full_path);

            @memcpy(window_cache.exe_name[0..filename.len], filename);
            window_cache.exe_name_len = filename.len;
        }

        std.debug.print("Window title: {s}\n", .{window_cache.window_title[0..window_cache.window_title_len]});
        std.debug.print("Exe: {s}\n", .{window_cache.exe_name[0..window_cache.exe_name_len]});
    }
}

pub fn install(
    callback: *const fn (types.KeyEvent, *stats.TypingStats) void,
    key_log_stats: *stats.TypingStats
) !void {
    global_callback = callback;
    key_stats = key_log_stats;

    // SetWindowsHookEx with WH_KEYBOARD_LL
    // Ref: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowshookexa
    // idHook: WH_KEYBOARD_LL (13) - low-level keyboard hook
    // lpfn: Hook procedure
    // hMod: NULL for low-level hooks (they run in calling thread's context)
    // dwThreadId: 0 for system-wide hook
    win_hooks.keyboard_hook = win32.SetWindowsHookExA(
        win32.WH_KEYBOARD_LL,  // 13
        hookProc,
        null,  // Must be NULL for WH_KEYBOARD_LL
        0,     // 0 = monitor all threads (system-wide)
    ) orelse return error.KeyboardHookInstallFailed;

    win_hooks.window_foreground_hook = win32.SetWinEventHook(
        win32.EVENT_SYSTEM_FOREGROUND,
        win32.EVENT_SYSTEM_FOREGROUND,
        null,
        winEventProc,
        0,
        0,
        win32.WINEVENT_OUTOFCONTEXT
    ) orelse return error.WindowHookInstallFailed;
}

// Ref: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-unhookwindowshookex
pub fn uninstall() void {
    _ = win32.UnhookWindowsHookEx(win_hooks.keyboard_hook);
    _ = win32.UnhookWinEvent(win_hooks.window_foreground_hook);
    global_callback = null;
}

// Necessary for Debug and Release safe, in ReleaseFast or ReleaseSmall @ptrFromInt can be
// used instead when casting from usize back to windows handle ptr
// const hhook: win32.HHOOK = unsafePtrCast(hook);
fn unsafePtrCast(value: usize) win32.HHOOK {
    @setRuntimeSafety(false);
    return @ptrFromInt(value);
}

// Process Windows message queue
// This hook is called in the context of the thread that installed it. The call is made by sending
// a message to the thread that installed the hook. Therefore, the thread that installed the hook
// must have a message loop.
// Ref: https://learn.microsoft.com/en-us/windows/win32/winmsg/using-hooks
pub fn pollEvents() void {
    var msg: win32.MSG = undefined;
    // PM_REMOVE: Remove messages from queue after processing
    // Non-blocking: Only process messages currently in queue
    while (win32.PeekMessageA(&msg, null, 0, 0, win32.PM_REMOVE) != 0) {
        _ = win32.TranslateMessage(&msg);
        _ = win32.DispatchMessageA(&msg);
    }
}

pub const win32_vk_to_usb_hid: [256]u8 = blk: {
    @setEvalBranchQuota(10000);
    var table: [256]u8 = [_]u8{0} ** 256;

    // Letters A-Z (VK_A = 0x41 to VK_Z = 0x5A)
    table[0x41] = @intFromEnum(stats.UsbHidKey.A);
    table[0x42] = @intFromEnum(stats.UsbHidKey.B);
    table[0x43] = @intFromEnum(stats.UsbHidKey.C);
    table[0x44] = @intFromEnum(stats.UsbHidKey.D);
    table[0x45] = @intFromEnum(stats.UsbHidKey.E);
    table[0x46] = @intFromEnum(stats.UsbHidKey.F);
    table[0x47] = @intFromEnum(stats.UsbHidKey.G);
    table[0x48] = @intFromEnum(stats.UsbHidKey.H);
    table[0x49] = @intFromEnum(stats.UsbHidKey.I);
    table[0x4A] = @intFromEnum(stats.UsbHidKey.J);
    table[0x4B] = @intFromEnum(stats.UsbHidKey.K);
    table[0x4C] = @intFromEnum(stats.UsbHidKey.L);
    table[0x4D] = @intFromEnum(stats.UsbHidKey.M);
    table[0x4E] = @intFromEnum(stats.UsbHidKey.N);
    table[0x4F] = @intFromEnum(stats.UsbHidKey.O);
    table[0x50] = @intFromEnum(stats.UsbHidKey.P);
    table[0x51] = @intFromEnum(stats.UsbHidKey.Q);
    table[0x52] = @intFromEnum(stats.UsbHidKey.R);
    table[0x53] = @intFromEnum(stats.UsbHidKey.S);
    table[0x54] = @intFromEnum(stats.UsbHidKey.T);
    table[0x55] = @intFromEnum(stats.UsbHidKey.U);
    table[0x56] = @intFromEnum(stats.UsbHidKey.V);
    table[0x57] = @intFromEnum(stats.UsbHidKey.W);
    table[0x58] = @intFromEnum(stats.UsbHidKey.X);
    table[0x59] = @intFromEnum(stats.UsbHidKey.Y);
    table[0x5A] = @intFromEnum(stats.UsbHidKey.Z);

    // Numbers 0-9 (VK_0 = 0x30 to VK_9 = 0x39)
    table[0x30] = @intFromEnum(stats.UsbHidKey.Num0);
    table[0x31] = @intFromEnum(stats.UsbHidKey.Num1);
    table[0x32] = @intFromEnum(stats.UsbHidKey.Num2);
    table[0x33] = @intFromEnum(stats.UsbHidKey.Num3);
    table[0x34] = @intFromEnum(stats.UsbHidKey.Num4);
    table[0x35] = @intFromEnum(stats.UsbHidKey.Num5);
    table[0x36] = @intFromEnum(stats.UsbHidKey.Num6);
    table[0x37] = @intFromEnum(stats.UsbHidKey.Num7);
    table[0x38] = @intFromEnum(stats.UsbHidKey.Num8);
    table[0x39] = @intFromEnum(stats.UsbHidKey.Num9);

    // Special keys
    table[0x08] = @intFromEnum(stats.UsbHidKey.Backspace);  // VK_BACK
    table[0x09] = @intFromEnum(stats.UsbHidKey.Tab);        // VK_TAB
    table[0x0D] = @intFromEnum(stats.UsbHidKey.Enter);      // VK_RETURN
    table[0x1B] = @intFromEnum(stats.UsbHidKey.Escape);     // VK_ESCAPE
    table[0x20] = @intFromEnum(stats.UsbHidKey.Space);      // VK_SPACE

    // Navigation keys
    table[0x21] = @intFromEnum(stats.UsbHidKey.PageUp);     // VK_PRIOR
    table[0x22] = @intFromEnum(stats.UsbHidKey.PageDown);   // VK_NEXT
    table[0x23] = @intFromEnum(stats.UsbHidKey.End);        // VK_END
    table[0x24] = @intFromEnum(stats.UsbHidKey.Home);       // VK_HOME

    // Arrow keys
    table[0x25] = @intFromEnum(stats.UsbHidKey.LeftArrow);  // VK_LEFT
    table[0x26] = @intFromEnum(stats.UsbHidKey.UpArrow);    // VK_UP
    table[0x27] = @intFromEnum(stats.UsbHidKey.RightArrow); // VK_RIGHT
    table[0x28] = @intFromEnum(stats.UsbHidKey.DownArrow);  // VK_DOWN

    // Select, Print, Execute
    table[0x29] = @intFromEnum(stats.UsbHidKey.Select);     // VK_SELECT
    table[0x2A] = @intFromEnum(stats.UsbHidKey.Execute);    // VK_EXECUTE (not print)
    table[0x2C] = @intFromEnum(stats.UsbHidKey.PrintScreen);// VK_SNAPSHOT
    table[0x2D] = @intFromEnum(stats.UsbHidKey.Insert);     // VK_INSERT
    table[0x2E] = @intFromEnum(stats.UsbHidKey.Delete);     // VK_DELETE
    table[0x2F] = @intFromEnum(stats.UsbHidKey.Help);       // VK_HELP

    // Modifier keys
    table[0x10] = @intFromEnum(stats.UsbHidKey.LeftShift);  // VK_SHIFT (generic)
    table[0x11] = @intFromEnum(stats.UsbHidKey.LeftCtrl);   // VK_CONTROL (generic)
    table[0x12] = @intFromEnum(stats.UsbHidKey.LeftAlt);    // VK_MENU (generic)

    // Extended modifier keys (with scan code differentiation)
    table[0xA0] = @intFromEnum(stats.UsbHidKey.LeftShift);  // VK_LSHIFT
    table[0xA1] = @intFromEnum(stats.UsbHidKey.RightShift); // VK_RSHIFT
    table[0xA2] = @intFromEnum(stats.UsbHidKey.LeftCtrl);   // VK_LCONTROL
    table[0xA3] = @intFromEnum(stats.UsbHidKey.RightCtrl);  // VK_RCONTROL
    table[0xA4] = @intFromEnum(stats.UsbHidKey.LeftAlt);    // VK_LMENU
    table[0xA5] = @intFromEnum(stats.UsbHidKey.RightAlt);   // VK_RMENU

    // Windows/Super keys
    table[0x5B] = @intFromEnum(stats.UsbHidKey.LeftGui);    // VK_LWIN
    table[0x5C] = @intFromEnum(stats.UsbHidKey.RightGui);   // VK_RWIN
    table[0x5D] = @intFromEnum(stats.UsbHidKey.Application);// VK_APPS (context menu)

    // Function keys F1-F12
    table[0x70] = @intFromEnum(stats.UsbHidKey.F1);
    table[0x71] = @intFromEnum(stats.UsbHidKey.F2);
    table[0x72] = @intFromEnum(stats.UsbHidKey.F3);
    table[0x73] = @intFromEnum(stats.UsbHidKey.F4);
    table[0x74] = @intFromEnum(stats.UsbHidKey.F5);
    table[0x75] = @intFromEnum(stats.UsbHidKey.F6);
    table[0x76] = @intFromEnum(stats.UsbHidKey.F7);
    table[0x77] = @intFromEnum(stats.UsbHidKey.F8);
    table[0x78] = @intFromEnum(stats.UsbHidKey.F9);
    table[0x79] = @intFromEnum(stats.UsbHidKey.F10);
    table[0x7A] = @intFromEnum(stats.UsbHidKey.F11);
    table[0x7B] = @intFromEnum(stats.UsbHidKey.F12);

    // Function keys F13-F24   stats.
    table[0x7C] = @intFromEnum(stats.UsbHidKey.F13);
    table[0x7D] = @intFromEnum(stats.UsbHidKey.F14);
    table[0x7E] = @intFromEnum(stats.UsbHidKey.F15);
    table[0x7F] = @intFromEnum(stats.UsbHidKey.F16);
    table[0x80] = @intFromEnum(stats.UsbHidKey.F17);
    table[0x81] = @intFromEnum(stats.UsbHidKey.F18);
    table[0x82] = @intFromEnum(stats.UsbHidKey.F19);
    table[0x83] = @intFromEnum(stats.UsbHidKey.F20);
    table[0x84] = @intFromEnum(stats.UsbHidKey.F21);
    table[0x85] = @intFromEnum(stats.UsbHidKey.F22);
    table[0x86] = @intFromEnum(stats.UsbHidKey.F23);
    table[0x87] = @intFromEnum(stats.UsbHidKey.F24);

    // Lock keys
    table[0x14] = @intFromEnum(stats.UsbHidKey.CapsLock);   // VK_CAPITAL
    table[0x90] = @intFromEnum(stats.UsbHidKey.NumLock);    // VK_NUMLOCK
    table[0x91] = @intFromEnum(stats.UsbHidKey.ScrollLock); // VK_SCROLL

    // Numpad keys
    table[0x60] = @intFromEnum(stats.UsbHidKey.Keypad0);    // VK_NUMPAD0
    table[0x61] = @intFromEnum(stats.UsbHidKey.Keypad1);    // VK_NUMPAD1
    table[0x62] = @intFromEnum(stats.UsbHidKey.Keypad2);    // VK_NUMPAD2
    table[0x63] = @intFromEnum(stats.UsbHidKey.Keypad3);    // VK_NUMPAD3
    table[0x64] = @intFromEnum(stats.UsbHidKey.Keypad4);    // VK_NUMPAD4
    table[0x65] = @intFromEnum(stats.UsbHidKey.Keypad5);    // VK_NUMPAD5
    table[0x66] = @intFromEnum(stats.UsbHidKey.Keypad6);    // VK_NUMPAD6
    table[0x67] = @intFromEnum(stats.UsbHidKey.Keypad7);    // VK_NUMPAD7
    table[0x68] = @intFromEnum(stats.UsbHidKey.Keypad8);    // VK_NUMPAD8
    table[0x69] = @intFromEnum(stats.UsbHidKey.Keypad9);    // VK_NUMPAD9

    table[0x6A] = @intFromEnum(stats.UsbHidKey.KeypadMultiply); // VK_MULTIPLY
    table[0x6B] = @intFromEnum(stats.UsbHidKey.KeypadPlus);     // VK_ADD
    table[0x6D] = @intFromEnum(stats.UsbHidKey.KeypadMinus);    // VK_SUBTRACT
    table[0x6E] = @intFromEnum(stats.UsbHidKey.KeypadDecimal);  // VK_DECIMAL
    table[0x6F] = @intFromEnum(stats.UsbHidKey.KeypadDivide);   // VK_DIVIDE

    // Symbol keys (punctuationstats.)
    table[0xBA] = @intFromEnum(stats.UsbHidKey.Semicolon);      // VK_OEM_1 (;:)
    table[0xBB] = @intFromEnum(stats.UsbHidKey.Equal);          // VK_OEM_PLUS (=+)
    table[0xBC] = @intFromEnum(stats.UsbHidKey.Comma);          // VK_OEM_COMMA (,<)
    table[0xBD] = @intFromEnum(stats.UsbHidKey.Minus);          // VK_OEM_MINUS (-_)
    table[0xBE] = @intFromEnum(stats.UsbHidKey.Period);         // VK_OEM_PERIOD (.>)
    table[0xBF] = @intFromEnum(stats.UsbHidKey.Slash);          // VK_OEM_2 (/?)
    table[0xC0] = @intFromEnum(stats.UsbHidKey.Grave);          // VK_OEM_3 (`~)
    table[0xDB] = @intFromEnum(stats.UsbHidKey.LeftBracket);    // VK_OEM_4 ([{)
    table[0xDC] = @intFromEnum(stats.UsbHidKey.Backslash);      // VK_OEM_5 (\|)
    table[0xDD] = @intFromEnum(stats.UsbHidKey.RightBracket);   // VK_OEM_6 (]})
    table[0xDE] = @intFromEnum(stats.UsbHidKey.Apostrophe);     // VK_OEM_7 ('")

    // Pause/Break
    table[0x13] = @intFromEnum(stats.UsbHidKey.Pause);          // VK_PAUSE

    // Multimedia keys
    table[0xAD] = @intFromEnum(stats.UsbHidKey.Mute);           // VK_VOLUME_MUTE
    table[0xAE] = @intFromEnum(stats.UsbHidKey.VolumeDown);     // VK_VOLUME_DOWN
    table[0xAF] = @intFromEnum(stats.UsbHidKey.VolumeUp);       // VK_VOLUME_UP

    break :blk table;
};

/// Convert Windows VK code to USB HID key
pub fn vkToUsbHid(vk_code: u32) stats.UsbHidKey {
    if (vk_code > 0xFF) return .None;
    const hid_code = win32_vk_to_usb_hid[vk_code];
    return @enumFromInt(hid_code);
}





