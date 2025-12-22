

/// USB HID Keyboard/Keypad Page scan codes
/// Reference: USB HID Usage Tables v1.4, Section 10*, page 90* (Keyboard/Keypad Page)
/// https://usb.org/sites/default/files/hut1_4.pdf
pub const UsbHidKey = enum(u8) {
    // Error codes
    None = 0x00,
    ErrorRollOver = 0x01,
    POSTFail = 0x02,
    ErrorUndefined = 0x03,

    // Letters A-Z (0x04-0x1D)
    A = 0x04, B = 0x05, C = 0x06, D = 0x07, E = 0x08,
    F = 0x09, G = 0x0A, H = 0x0B, I = 0x0C, J = 0x0D,
    K = 0x0E, L = 0x0F, M = 0x10, N = 0x11, O = 0x12,
    P = 0x13, Q = 0x14, R = 0x15, S = 0x16, T = 0x17,
    U = 0x18, V = 0x19, W = 0x1A, X = 0x1B, Y = 0x1C,
    Z = 0x1D,

    // Numbers 1-0 (0x1E-0x27)
    Num1 = 0x1E, Num2 = 0x1F, Num3 = 0x20, Num4 = 0x21,
    Num5 = 0x22, Num6 = 0x23, Num7 = 0x24, Num8 = 0x25,
    Num9 = 0x26, Num0 = 0x27,

    // Special keys (0x28-0x38)
    Enter = 0x28,
    Escape = 0x29,
    Backspace = 0x2A,
    Tab = 0x2B,
    Space = 0x2C,
    Minus = 0x2D,           // - and _
    Equal = 0x2E,           // = and +
    LeftBracket = 0x2F,     // [ and {
    RightBracket = 0x30,    // ] and }
    Backslash = 0x31,       // \ and |
    NonUSHash = 0x32,       // Non-US # and ~
    Semicolon = 0x33,       // ; and :
    Apostrophe = 0x34,      // ' and "
    Grave = 0x35,           // ` and ~
    Comma = 0x36,           // , and 
    Period = 0x37,          // . and >
    Slash = 0x38,           // / and ?
    
    // Function and navigation (0x39-0x45)
    CapsLock = 0x39,
    F1 = 0x3A, F2 = 0x3B,   F3 = 0x3C,  F4 = 0x3D,
    F5 = 0x3E, F6 = 0x3F,   F7 = 0x40,  F8 = 0x41,
    F9 = 0x42, F10 = 0x43, F11 = 0x44, F12 = 0x45,

    // System keys (0x46-0x4E)
    PrintScreen = 0x46,
    ScrollLock = 0x47,
    Pause = 0x48,
    Insert = 0x49,
    Home = 0x4A,
    PageUp = 0x4B,
    Delete = 0x4C,
    End = 0x4D,
    PageDown = 0x4E,

    // Arrow keys (0x4F-0x52)
    RightArrow = 0x4F,
    LeftArrow = 0x50,
    DownArrow = 0x51,
    UpArrow = 0x52,

    // Keypad (0x53-0x63)
    NumLock = 0x53,
    KeypadDivide = 0x54,
    KeypadMultiply = 0x55,
    KeypadMinus = 0x56,
    KeypadPlus = 0x57,
    KeypadEnter = 0x58,
    Keypad1 = 0x59, Keypad2 = 0x5A, Keypad3 = 0x5B,
    Keypad4 = 0x5C, Keypad5 = 0x5D, Keypad6 = 0x5E,
    Keypad7 = 0x5F, Keypad8 = 0x60, Keypad9 = 0x61,
    Keypad0 = 0x62,
    KeypadDecimal = 0x63,

    // International keys (0x64-0x65)
    NonUSBackslash = 0x64,  // Non-US \ and |
    Application = 0x65,     // Windows context menu key
    
    // Power and more function keys (0x66-0x73)
    Power = 0x66,
    KeypadEqual = 0x67,
    F13 = 0x68, F14 = 0x69, F15 = 0x6A, F16 = 0x6B,
    F17 = 0x6C, F18 = 0x6D, F19 = 0x6E, F20 = 0x6F,
    F21 = 0x70, F22 = 0x71, F23 = 0x72, F24 = 0x73,

    // Extended keys (0x74-0x87)
    Execute = 0x74,
    Help = 0x75,
    Menu = 0x76,
    Select = 0x77,
    Stop = 0x78,
    Again = 0x79,
    Undo = 0x7A,
    Cut = 0x7B,
    Copy = 0x7C,
    Paste = 0x7D,
    Find = 0x7E,
    Mute = 0x7F,
    VolumeUp = 0x80,
    VolumeDown = 0x81,
    LockingCapsLock = 0x82,
    LockingNumLock = 0x83,
    LockingScrollLock = 0x84,
    KeypadComma = 0x85,
    KeypadEqualSign = 0x86,
    International1 = 0x87,  // Ro (Japanese)
    
    // More international (0x88-0x8F)
    International2 = 0x88,  // Katakana/Hiragana
    International3 = 0x89,  // Yen
    International4 = 0x8A,  // Henkan
    International5 = 0x8B,  // Muhenkan
    International6 = 0x8C,  // PC9800 Keypad Comma
    International7 = 0x8D,  // Toggle Double-Byte/Single-Byte mod
    International8 = 0x8E,
    International9 = 0x8F,

    // Language keys (0x90-0x99)
    Lang1 = 0x90,           // Hangul/English (Korean)
    Lang2 = 0x91,           // Hanja (Korean)
    Lang3 = 0x92,           // Katakana (Japanese)
    Lang4 = 0x93,           // Hiragana (Japanese)
    Lang5 = 0x94,           // Zenkaku/Hankaku (Japanese)
    Lang6 = 0x95,
    Lang7 = 0x96,
    Lang8 = 0x97,
    Lang9 = 0x98,
    AlternateErase = 0x99,

    // System control (0x9A-0xA4)
    SysReqAttention = 0x9A,
    Cancel = 0x9B,
    Clear = 0x9C,
    Prior = 0x9D,
    Return = 0x9E,
    Separator = 0x9F,
    Out = 0xA0,
    Oper = 0xA1,
    ClearAgain = 0xA2,
    CrSelProps = 0xA3,
    ExSel = 0xA4,

    // Modifiers (0xE0-0xE7)
    LeftCtrl = 0xE0,
    LeftShift = 0xE1,
    LeftAlt = 0xE2,
    LeftGui = 0xE3,         // Windows/Command/Super key
    RightCtrl = 0xE4,
    RightShift = 0xE5,
    RightAlt = 0xE6,
    RightGui = 0xE7,        // Windows/Command/Super key

    pub fn isAlpahNumeric(self: UsbHidKey) bool {
        return 0x04 <= @as(u8, self) and @as(u8, self) <= 0x27;
    }

    pub fn isModifier(self: UsbHidKey) bool {
        return 0xE0 <= self and self <= 0xE8;
    }

    /// Helper to get human-readable full name
    pub fn getName(self: UsbHidKey) []const u8 {
        return switch (self) {
            // Letters A-Z
            .A => "A", .B => "B", .C => "C", .D => "D", .E => "E",
            .F => "F", .G => "G", .H => "H", .I => "I", .J => "J",
            .K => "K", .L => "L", .M => "M", .N => "N", .O => "O",
            .P => "P", .Q => "Q", .R => "R", .S => "S", .T => "T",
            .U => "U", .V => "V", .W => "W", .X => "X", .Y => "Y",
            .Z => "Z",

            // Numbers 1-0
            .Num0 => "0", .Num1 => "1", .Num2 => "2", .Num3 => "3", .Num4 => "4",
            .Num5 => "5", .Num6 => "6", .Num7 => "7", .Num8 => "8", .Num9 => "9",

            // Special keys
            .Enter => "Enter",
            .Escape => "Escape",
            .Backspace => "Backspace",
            .Tab => "Tab",
            .Space => "Space",
            .Minus => "-",
            .Equal => "=",
            .LeftBracket => "[",
            .RightBracket => "]",
            .Backslash => "\\",
            .NonUSHash => "#",
            .Semicolon => ";",
            .Apostrophe => "'",
            .Grave => "`",
            .Comma => ",",
            .Period => ".",
            .Slash => "/",

            // Function and navigation
            .CapsLock => "Caps Lock",
            .F1 => "F1", .F2 => "F2", .F3 => "F3", .F4 => "F4",
            .F5 => "F5", .F6 => "F6", .F7 => "F7", .F8 => "F8",
            .F9 => "F9", .F10 => "F10", .F11 => "F11", .F12 => "F12",

            // System keys
            .PrintScreen => "Print Screen",
            .ScrollLock => "Scroll Lock",
            .Pause => "Pause",
            .Insert => "Insert",
            .Home => "Home",
            .PageUp => "Page Up",
            .Delete => "Delete",
            .End => "End",
            .PageDown => "Page Down",

            // Arrow keys
            .RightArrow => "Right Arrow",
            .LeftArrow => "Left Arrow",
            .DownArrow => "Down Arrow",
            .UpArrow => "Up Arrow",

            // Keypad
            .NumLock => "Num Lock",
            .KeypadDivide => "/",
            .KeypadMultiply => "*",
            .KeypadMinus => "-",
            .KeypadPlus => "+",
            .KeypadEnter => "Enter",
            .Keypad1 => "1", .Keypad2 => "2", .Keypad3 => "3",
            .Keypad4 => "4", .Keypad5 => "5", .Keypad6 => "6",
            .Keypad7 => "7", .Keypad8 => "8", .Keypad9 => "9",
            .Keypad0 => "0",
            .KeypadDecimal => ".",

            // International keys
            .NonUSBackslash => "\\",
            .Application => "App",

            // Power and more function keys
            .Power => "Power",
            .KeypadEqual => "=",
            .F13 => "F13", .F14 => "F14", .F15 => "F15", .F16 => "F16",
            .F17 => "F17", .F18 => "F18", .F19 => "F19", .F20 => "F20",
            .F21 => "F21", .F22 => "F22", .F23 => "F23", .F24 => "F24",

            // Extended keys
            .Execute => "Execute",
            .Help => "Help",
            .Menu => "Menu",
            .Select => "Select",
            .Stop => "Stop",
            .Again => "Again",
            .Undo => "Undo",
            .Cut => "Cut",
            .Copy => "Copy",
            .Paste => "Paste",
            .Find => "Find",
            .Mute => "Mute",
            .VolumeUp => "Vol+",
            .VolumeDown => "Vol-",
            .LockingCapsLock => "Locking Caps",
            .LockingNumLock => "Locking Num",
            .LockingScrollLock => "Locking Scroll",
            .KeypadComma => ",",
            .KeypadEqualSign => "=",
            .International1 => "Ro",

            // More international
            .International2 => "Katakana",
            .International3 => "Yen",
            .International4 => "Henkan",
            .International5 => "Muhenkan",
            .International6 => "PC98 Comma",
            .International7 => "Toggle Byte",
            .International8 => "Int8",
            .International9 => "Int9",

            // Language keys
            .Lang1 => "Hangul",
            .Lang2 => "Hanja",
            .Lang3 => "Katakana",
            .Lang4 => "Hiragana",
            .Lang5 => "Zenkaku",
            .Lang6 => "Lang6",
            .Lang7 => "Lang7",
            .Lang8 => "Lang8",
            .Lang9 => "Lang9",
            .AlternateErase => "Alt Erase",

            // System control
            .SysReqAttention => "SysReq",
            .Cancel => "Cancel",
            .Clear => "Clear",
            .Prior => "Prior",
            .Return => "Return",
            .Separator => "Separator",
            .Out => "Out",
            .Oper => "Oper",
            .ClearAgain => "Clear Again",
            .CrSelProps => "CrSel",
            .ExSel => "ExSel",

            // Modifiers
            .LeftCtrl => "Left Ctrl",
            .LeftShift => "Left Shift",
            .LeftAlt => "Left Alt",
            .LeftGui => "Left Super",
            .RightCtrl => "Right Ctrl",
            .RightShift => "Right Shift",
            .RightAlt => "Right Alt",
            .RightGui => "Right Super",

            // Error codes
            .None => "None",
            .ErrorRollOver => "Error Rollover",
            .POSTFail => "POST Fail",
            .ErrorUndefined => "Error Undefined",
        };
    }

    /// Helper to get printable label for keyboard display
    pub fn getLabel(self: UsbHidKey) []const u8 {
        return switch (self) {
            // Letters A-Z
            .A => "A", .B => "B", .C => "C", .D => "D", .E => "E",
            .F => "F", .G => "G", .H => "H", .I => "I", .J => "J",
            .K => "K", .L => "L", .M => "M", .N => "N", .O => "O",
            .P => "P", .Q => "Q", .R => "R", .S => "S", .T => "T",
            .U => "U", .V => "V", .W => "W", .X => "X", .Y => "Y",
            .Z => "Z",

            // Numbers 1-0
            .Num0 => "0", .Num1 => "1", .Num2 => "2", .Num3 => "3", .Num4 => "4",
            .Num5 => "5", .Num6 => "6", .Num7 => "7", .Num8 => "8", .Num9 => "9",

            // Special keys
            .Enter => "Enter",
            .Escape => "Esc",
            .Backspace => "Backspace",
            .Tab => "Tab",
            .Space => "Space",
            .Minus => "-",
            .Equal => "=",
            .LeftBracket => "[",
            .RightBracket => "]",
            .Backslash => "\\",
            .NonUSHash => "#",
            .Semicolon => ";",
            .Apostrophe => "'",
            .Grave => "`",
            .Comma => ",",
            .Period => ".",
            .Slash => "/",

            // Function and navigation
            .CapsLock => "Caps",
            .F1 => "F1", .F2 => "F2", .F3 => "F3", .F4 => "F4",
            .F5 => "F5", .F6 => "F6", .F7 => "F7", .F8 => "F8",
            .F9 => "F9", .F10 => "F10", .F11 => "F11", .F12 => "F12",

            // System keys
            .PrintScreen => "PrtSc",
            .ScrollLock => "ScrLk",
            .Pause => "Pause",
            .Insert => "Ins",
            .Home => "Home",
            .PageUp => "PgUp",
            .Delete => "Del",
            .End => "End",
            .PageDown => "PgDn",

            // Arrow keys
            .RightArrow => "->",
            .LeftArrow => "<-",
            .DownArrow => "<-",
            .UpArrow => "<-",

            // Keypad
            .NumLock => "Num",
            .KeypadDivide => "/",
            .KeypadMultiply => "*",
            .KeypadMinus => "-",
            .KeypadPlus => "+",
            .KeypadEnter => "Enter",
            .Keypad1 => "1", .Keypad2 => "2", .Keypad3 => "3",
            .Keypad4 => "4", .Keypad5 => "5", .Keypad6 => "6",
            .Keypad7 => "7", .Keypad8 => "8", .Keypad9 => "9",
            .Keypad0 => "0",
            .KeypadDecimal => ".",

            // International keys
            .NonUSBackslash => "\\",
            .Application => "App",

            // Power and more function keys
            .Power => "Pwr",
            .KeypadEqual => "=",
            .F13 => "F13", .F14 => "F14", .F15 => "F15", .F16 => "F16",
            .F17 => "F17", .F18 => "F18", .F19 => "F19", .F20 => "F20",
            .F21 => "F21", .F22 => "F22", .F23 => "F23", .F24 => "F24",

            // Extended keys
            .Execute => "Exec",
            .Help => "Help",
            .Menu => "Menu",
            .Select => "Sel",
            .Stop => "Stop",
            .Again => "Again",
            .Undo => "Undo",
            .Cut => "Cut",
            .Copy => "Copy",
            .Paste => "Paste",
            .Find => "Find",
            .Mute => "Mute",
            .VolumeUp => "Vol+",
            .VolumeDown => "Vol-",
            .LockingCapsLock => "Caps",
            .LockingNumLock => "Num",
            .LockingScrollLock => "Scrl",
            .KeypadComma => ",",
            .KeypadEqualSign => "=",
            .International1 => "Ro",

            // More international
            .International2 => "Kana",
            .International3 => "Yen",
            .International4 => "Henk",
            .International5 => "Muhe",
            .International6 => "PC98",
            .International7 => "Byte",
            .International8 => "Int8",
            .International9 => "Int9",

            // Language keys
            .Lang1 => "Han",
            .Lang2 => "Hanja",
            .Lang3 => "Kana",
            .Lang4 => "Hira",
            .Lang5 => "Zen",
            .Lang6 => "L6",
            .Lang7 => "L7",
            .Lang8 => "L8",
            .Lang9 => "L9",
            .AlternateErase => "AltEr",

            // System control
            .SysReqAttention => "SysRq",
            .Cancel => "Cncl",
            .Clear => "Clr",
            .Prior => "Prior",
            .Return => "Ret",
            .Separator => "Sep",
            .Out => "Out",
            .Oper => "Oper",
            .ClearAgain => "ClrAgn",
            .CrSelProps => "CrSel",
            .ExSel => "ExSel",

            // Modifiers
            .LeftCtrl => "Ctrl",
            .LeftShift => "Shift",
            .LeftAlt => "Alt",
            .LeftGui => "Win",
            .RightCtrl => "Ctrl",
            .RightShift => "Shift",
            .RightAlt => "Alt",
            .RightGui => "Win",

            // Error codes
            .None => "",
            .ErrorRollOver => "ERR",
            .POSTFail => "FAIL",
            .ErrorUndefined => "ERR",
        };
    }
};

/// X11 KeySym to USB HID scan code mapping
/// Reference: /usr/include/X11/keysymdef.h
/// KeySyms are sparse, so we use a switch instead of an array
pub fn keysymToUsbHid(keysym: u32) UsbHidKey {
    return switch (keysym) {
        // Lowercase letters (0x61-0x7A)
        0x61 => .A, 0x62 => .B, 0x63 => .C, 0x64 => .D, 0x65 => .E,
        0x66 => .F, 0x67 => .G, 0x68 => .H, 0x69 => .I, 0x6A => .J,
        0x6B => .K, 0x6C => .L, 0x6D => .M, 0x6E => .N, 0x6F => .O,
        0x70 => .P, 0x71 => .Q, 0x72 => .R, 0x73 => .S, 0x74 => .T,
        0x75 => .U, 0x76 => .V, 0x77 => .W, 0x78 => .X, 0x79 => .Y,
        0x7A => .Z,

        // Uppercase letters (0x41-0x5A)
        0x41 => .A, 0x42 => .B, 0x43 => .C, 0x44 => .D, 0x45 => .E,
        0x46 => .F, 0x47 => .G, 0x48 => .H, 0x49 => .I, 0x4A => .J,
        0x4B => .K, 0x4C => .L, 0x4D => .M, 0x4E => .N, 0x4F => .O,
        0x50 => .P, 0x51 => .Q, 0x52 => .R, 0x53 => .S, 0x54 => .T,
        0x55 => .U, 0x56 => .V, 0x57 => .W, 0x58 => .X, 0x59 => .Y,
        0x5A => .Z,

        // Numbers 0-9 (0x30-0x39)
        0x30 => .Num0, 0x31 => .Num1, 0x32 => .Num2, 0x33 => .Num3, 0x34 => .Num4,
        0x35 => .Num5, 0x36 => .Num6, 0x37 => .Num7, 0x38 => .Num8, 0x39 => .Num9,

        // Special keys
        0xFF08 => .Backspace,   // XK_BackSpace
        0xFF09 => .Tab,         // XK_Tab
        0xFF0D => .Enter,       // XK_Return
        0xFF1B => .Escape,      // XK_Escape
        0x0020 => .Space,       // XK_space (note: not in 0xFF range)

        // Navigation keys
        0xFF50 => .Home,        // XK_Home
        0xFF51 => .LeftArrow,   // XK_Left
        0xFF52 => .UpArrow,     // XK_Up
        0xFF53 => .RightArrow,  // XK_Right
        0xFF54 => .DownArrow,   // XK_Down
        0xFF55 => .PageUp,      // XK_Page_Up
        0xFF56 => .PageDown,    // XK_Page_Down
        0xFF57 => .End,         // XK_End

        // Editing keys
        0xFF63 => .Insert,      // XK_Insert
        0xFFFF => .Delete,      // XK_Delete

        // Modifier keys
        0xFFE1 => .LeftShift,   // XK_Shift_L
        0xFFE2 => .RightShift,  // XK_Shift_R
        0xFFE3 => .LeftCtrl,    // XK_Control_L
        0xFFE4 => .RightCtrl,   // XK_Control_R
        0xFFE9 => .LeftAlt,     // XK_Alt_L
        0xFFEA => .RightAlt,    // XK_Alt_R (also ISO_Level3_Shift)
        0xFFEB => .LeftGui,     // XK_Super_L (Windows/Command key)
        0xFFEC => .RightGui,    // XK_Super_R

        // Lock keys
        0xFFE5 => .CapsLock,    // XK_Caps_Lock
        0xFF7F => .NumLock,     // XK_Num_Lock
        0xFF14 => .ScrollLock,  // XK_Scroll_Lock

        // Function keys F1-F12
        0xFFBE => .F1,  0xFFBF => .F2,  0xFFC0 => .F3,  0xFFC1 => .F4,
        0xFFC2 => .F5,  0xFFC3 => .F6,  0xFFC4 => .F7,  0xFFC5 => .F8,
        0xFFC6 => .F9,  0xFFC7 => .F10, 0xFFC8 => .F11, 0xFFC9 => .F12,

        // Function keys F13-F24
        0xFFCA => .F13, 0xFFCB => .F14, 0xFFCC => .F15, 0xFFCD => .F16,
        0xFFCE => .F17, 0xFFCF => .F18, 0xFFD0 => .F19, 0xFFD1 => .F20,
        0xFFD2 => .F21, 0xFFD3 => .F22, 0xFFD4 => .F23, 0xFFD5 => .F24,

        // Keypad numbers
        0xFFB0 => .Keypad0, 0xFFB1 => .Keypad1, 0xFFB2 => .Keypad2,
        0xFFB3 => .Keypad3, 0xFFB4 => .Keypad4, 0xFFB5 => .Keypad5,
        0xFFB6 => .Keypad6, 0xFFB7 => .Keypad7, 0xFFB8 => .Keypad8,
        0xFFB9 => .Keypad9,

        // Keypad operators
        0xFFAA => .KeypadMultiply,  // XK_KP_Multiply
        0xFFAB => .KeypadPlus,      // XK_KP_Add
        0xFFAD => .KeypadMinus,     // XK_KP_Subtract
        0xFFAE => .KeypadDecimal,   // XK_KP_Decimal
        0xFFAF => .KeypadDivide,    // XK_KP_Divide
        0xFF8D => .KeypadEnter,     // XK_KP_Enter

        // Punctuation/symbols
        0x003B => .Semicolon,       // ; (semicolon)
        0x003A => .Semicolon,       // : (colon - shift+semicolon)
        0x003D => .Equal,           // = (equal)
        0x002B => .Equal,           // + (plus - shift+equal)
        0x002C => .Comma,           // , (comma)
        0x003C => .Comma,           // < (less - shift+comma)
        0x002D => .Minus,           // - (minus)
        0x005F => .Minus,           // _ (underscore - shift+minus)
        0x002E => .Period,          // . (period)
        0x003E => .Period,          // > (greater - shift+period)
        0x002F => .Slash,           // / (slash)
        0x003F => .Slash,           // ? (question - shift+slash)
        0x0060 => .Grave,           // ` (grave)
        0x007E => .Grave,           // ~ (tilde - shift+grave)
        0x005B => .LeftBracket,     // [ (left bracket)
        0x007B => .LeftBracket,     // { (left brace - shift+bracket)
        0x005C => .Backslash,       // \ (backslash)
        0x007C => .Backslash,       // | (pipe - shift+backslash)
        0x005D => .RightBracket,    // ] (right bracket)
        0x007D => .RightBracket,    // } (right brace - shift+bracket)
        0x0027 => .Apostrophe,      // ' (apostrophe)
        0x0022 => .Apostrophe,      // " (quote - shift+apostrophe)

        // System keys
        0xFF61 => .PrintScreen,     // XK_Print
        0xFF13 => .Pause,           // XK_Pause
        0xFF6B => .Pause,           // XK_Break (alternative)
        0xFF67 => .Menu,            // XK_Menu
        0xFF60 => .Select,          // XK_Select
        0xFF62 => .Execute,         // XK_Execute
        0xFF6A => .Help,            // XK_Help

        // Multimedia keys
        0x1008FF12 => .Mute,        // XF86XK_AudioMute
        0x1008FF11 => .VolumeDown,  // XF86XK_AudioLowerVolume
        0x1008FF13 => .VolumeUp,    // XF86XK_AudioRaiseVolume

        // Unknown/unmapped
        else => .None,
    };
}