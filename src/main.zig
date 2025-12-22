const std = @import("std");
const rl = @import("raylib");
const pf = @import("pf");
const stats = @import("stats");
const shader_content = @import("shader_content");

const VEC8_WIDTH = std.simd.suggestVectorLength(u8) orelse 32;
const VEC16_WIDTH = std.simd.suggestVectorLength(u16) orelse 16;
const VEC32_WIDTH = std.simd.suggestVectorLength(u32) orelse 8;
const VEC64_WIDTH = std.simd.suggestVectorLength(u64) orelse 4;


fn recordKeyEvent(event: pf.types.KeyEvent, key_stats: *stats.TypingStats) void {
    std.debug.print("Key code: 0x{x}\n", .{event.key_code});
    try key_stats.recordKeyStroke(event.timestamp, event.key_code);
}


const Vec2 = rl.Vector2;
const Vec3 = rl.Vector3;
const Color = rl.Color;
const Rectangle = rl.Rectangle;
const Font = rl.Font;

const Container = struct {
    id: ?[] u8,
    parent: ?*Container,
    vec: Vec3,
    bg_color: Color,
    text_color: Color,
    border_color: Color,
    text_size: u32,
    border_width: u32,
};

// fn getCenter(parent: Vec3, child: Vec3) void {
//
// }

const BaseKey = struct {
    width: f32,
    height: f32,
    angle: f32,
    right_padding: f32,
    roundedness: f32,
    text_angle: f32,
    text_color: Color,
    bg_color: Color,
    border_color: Color,
    border_width: f32,
    font_size: f32,
    font: *const Font,

    fn withExtraPadding(self: BaseKey, extra: f32) BaseKey {
        var result = self;
        result.right_padding += extra;
        return result;
    }

    fn withDifferentHeight(self: BaseKey, extra: f32) BaseKey {
        var result = self;
        result.height = extra;
        return result;
    }

    fn withDifferentWidth(self: BaseKey, extra: f32) BaseKey {
        var result = self;
        result.width = extra;
        return result;
    }

    fn with(self: BaseKey, comptime field: []const u8, value: anytype) BaseKey {
        var result = self;
        @field(result, field) = value;
        return result;
    }
};


const Key = struct {
    row: usize,
    base: *const BaseKey,
    usb_id: stats.UsbHidKey,
    center: Vec2,

    pub fn init(row: usize, base: *const BaseKey, usb_id: stats.UsbHidKey, center: Vec2) Key {
        return Key{ .row = row, .base = base, .usb_id = usb_id, .center = center };
    }

};

const Keys = struct {
    keys: []Key,

    pub fn init(key_list: []Key) Keys {
        return Keys{ .keys = key_list };
    }

    pub fn initAnsiKeyboard(allocator: std.mem.Allocator, base: *const BaseKey) !Keys {
        var ansi_keys = try makeRows(allocator, base, &.{
            .{ .row = 0, .keys = &.{
                .Escape,
                .F1, .F2, .F3, .F4,
                .F5, .F6, .F7, .F8,
                .F9, .F10, .F11, .F12,
                .PrintScreen, .ScrollLock, .Pause
            }},
            .{ .row = 1, .keys = &.{
                .Grave, .Num1, .Num2, .Num3, .Num4, .Num5, .Num6, .Num7, .Num8, .Num9, .Num0, .Minus, .Equal, .Backspace,
                .Insert, .Home, .PageUp,
                .NumLock, .KeypadDivide, .KeypadMultiply, .KeypadMinus
            }},
            .{ .row = 2, .keys = &.{
                .Tab, .Q, .W, .E, .R, .T, .Y, .U, .I, .O, .P, .LeftBracket, .RightBracket, .Backslash,
                .Delete, .End, .PageDown,
                .Keypad7, .Keypad8, .Keypad9, .KeypadPlus
            }},
            .{ .row = 3, .keys = &.{
                .CapsLock, .A, .S, .D, .F, .G, .H, .J, .K, .L, .Semicolon, .Apostrophe, .Enter,
                .Keypad4, .Keypad5, .Keypad6
            }},
            .{ .row = 4, .keys = &.{
                .LeftShift, .Z, .X, .C, .V, .B, .N, .M, .Comma, .Period, .Slash, .RightShift,
                .UpArrow,
                .Keypad1, .Keypad2, .Keypad3, .KeypadEnter
            }},
            .{ .row = 5, .keys = &.{
                .LeftCtrl, .LeftGui, .LeftAlt, .Space, .RightAlt, .RightGui, .Menu, .RightCtrl,
                .LeftArrow, .DownArrow, .RightArrow,
                .Keypad0, .KeypadDecimal
            }},
        });

        const space = base.width * 0.15;

        // Ansi special keys
        const esc = try allocator.create(BaseKey);
        esc.* = base.withExtraPadding(base.width + space);

        const f4 = try allocator.create(BaseKey);
        f4.* = base.withExtraPadding(base.width * 0.5);

        const f8 = try allocator.create(BaseKey);
        f8.* = base.withExtraPadding(base.width * 0.5);

        const f12 = try allocator.create(BaseKey);
        f12.* = base.withExtraPadding(base.width * 0.5);

        const backspace = try allocator.create(BaseKey);
        backspace.* = base.withDifferentWidth(base.width * 2)
        .withExtraPadding(base.width * 1.5);

        const tab = try allocator.create(BaseKey);
        tab.* = base.withDifferentWidth(base.width * 1.5)
        .withExtraPadding(base.width * 0.5);

        const backslash = try allocator.create(BaseKey);
        backslash.* = base.withDifferentWidth(base.width * 1.5)
        .withExtraPadding(base.width);

        const caps = try allocator.create(BaseKey);
        caps.* = base.withDifferentWidth(base.width * 1.75)
        .withExtraPadding(base.width * 0.75);

        const enter = try allocator.create(BaseKey);
        enter.* = base.withDifferentWidth(base.width * (2.25 + 0.15))
        .withExtraPadding((base.width * (1.25 + 0.15)) + (base.width * 4) + (space * 3));

        const left_shift = try allocator.create(BaseKey);
        left_shift.* = base.withDifferentWidth(base.width * (2.25 + 0.15))
        .withExtraPadding(base.width * (1.25 + 0.15));

        const right_shift = try allocator.create(BaseKey);
        right_shift.* = base.withDifferentWidth(base.width * (2.75 + 0.15))
        .withExtraPadding(base.width * (1.75 + 0.15) + (base.width * 1.5) + space);

        const up_arrow = try allocator.create(BaseKey);
        up_arrow.* = base.with("text_angle", 90)
        .withExtraPadding(base.width * 1.5 + space);

        const ctrl_size = base.width * (1.2125 + 0.15);

        const left_ctrl = try allocator.create(BaseKey);
        left_ctrl.* = base.withDifferentWidth(ctrl_size)
        .withExtraPadding(base.width * (0.2125 + 0.15));

        const left_gui = try allocator.create(BaseKey);
        left_gui.* = base.withDifferentWidth(ctrl_size)
        .withExtraPadding(base.width * (0.2125 + 0.15));

        const left_alt = try allocator.create(BaseKey);
        left_alt.* = base.withDifferentWidth(ctrl_size)
        .withExtraPadding(base.width * (0.2125 + 0.15));

        const right_alt = try allocator.create(BaseKey);
        right_alt.* = base.withDifferentWidth(ctrl_size)
        .withExtraPadding(base.width * (0.2125 + 0.15));

        const right_gui = try allocator.create(BaseKey);
        right_gui.* = base.withDifferentWidth(ctrl_size)
        .withExtraPadding(base.width * (0.2125 + 0.15));

        const menu = try allocator.create(BaseKey);
        menu.* = base.withDifferentWidth(ctrl_size)
        .withExtraPadding(base.width * (0.2125 + 0.15));

        const right_ctrl = try allocator.create(BaseKey);
        right_ctrl.* = base.withDifferentWidth(ctrl_size)
        .withExtraPadding(base.width * (0.2125 + 0.15 + 0.5));

        const spacebar = try allocator.create(BaseKey);
        spacebar.* = base.withDifferentWidth(base.width * (6.2125 + 0.15))
        .withExtraPadding(base.width * (5.2125 + 0.15));

        const down_arrow = try allocator.create(BaseKey);
        down_arrow.* = base.with("text_angle", -90);

        const right_arrow = try allocator.create(BaseKey);
        right_arrow.* = base.withExtraPadding(base.width * 0.5);

        const keypad_plus = try allocator.create(BaseKey);
        keypad_plus.* = base.withDifferentHeight((base.height * 2) + space);

        const keypad_enter = try allocator.create(BaseKey);
        keypad_enter.* = base.withDifferentHeight((base.height * 2) + space);

        const keypad_0 = try allocator.create(BaseKey);
        keypad_0.* = base.withDifferentWidth((base.width * 2) + space)
        .withExtraPadding(base.width + space);

        const page_up = try allocator.create(BaseKey);
        page_up.* = base.withExtraPadding(base.width * 0.5);

        const page_down = try allocator.create(BaseKey);
        page_down.* = base.withExtraPadding(base.width * 0.5);

        introduceExceptions(ansi_keys[0..], &.{
            .{ .key = .Escape, .base = esc },
            .{ .key = .F4, .base = f4 },
            .{ .key = .F8, .base = f8 },
            .{ .key = .F12, .base = f12 },
            .{ .key = .Backspace, .base = backspace },
            .{ .key = .Tab, .base = tab },
            .{ .key = .Backslash, .base = backslash },
            .{ .key = .PageUp, .base = page_up },
            .{ .key = .PageDown, .base = page_down },
            .{ .key = .CapsLock, .base = caps },
            .{ .key = .Enter, .base = enter },
            .{ .key = .LeftShift, .base = left_shift },
            .{ .key = .RightShift, .base = right_shift },
            .{ .key = .UpArrow, .base = up_arrow },
            .{ .key = .LeftCtrl, .base = left_ctrl },
            .{ .key = .LeftGui, .base = left_gui },
            .{ .key = .LeftAlt, .base = left_alt },
            .{ .key = .Space, .base = spacebar },
            .{ .key = .RightAlt, .base = right_alt },
            .{ .key = .RightGui, .base = right_gui },
            .{ .key = .Menu, .base = menu },
            .{ .key = .RightCtrl, .base = right_ctrl },
            .{ .key = .DownArrow, .base = down_arrow },
            .{ .key = .RightArrow, .base = right_arrow },
            .{ .key = .KeypadPlus, .base = keypad_plus },
            .{ .key = .KeypadEnter, .base = keypad_enter },
            .{ .key = .Keypad0, .base = keypad_0 },
        });

        return Keys.init(ansi_keys);
    }

};

fn makeRows(
    allocator: std.mem.Allocator,
    base: *const BaseKey,
    rows: []const struct { row: usize, keys: []const stats.UsbHidKey }
) ![]Key {
    var total_len: usize = 0;
    for (rows) |r| total_len += r.keys.len;

    var result = try allocator.alloc(Key, total_len);
    var idx: usize = 0;
    for (rows) |row| {
        for (row.keys) |key_id| {
            result[idx] = Key.init(row.row, base, key_id, Vec2{ .x = 0, .y = 0});
            idx += 1;
        }
    }
    return result;
}

fn introduceExceptions(
    keys: []Key, exceptions: []const struct { key: stats.UsbHidKey, base: *const BaseKey }
) void {
    for (exceptions) |exception| {
        for (keys) |*key| {
            if (key.usb_id == exception.key) {
                key.base = exception.base;
            }
        }
    }
}

fn drawKey(key: *Key, rec: *Rectangle, text_size: Vec2, key_name: [:0]const u8) void {
    rec.height = key.base.height;
    rec.width = key.base.width;
    rl.drawRectangleRounded(
        rec.*,
        key.base.roundedness,
        8,
        rl.Color{ .r = 10, .g = 10, .b = 10, .a = 50 }  // Dark semi-transparent
    );

    rl.drawRectangleRoundedLinesEx(
        rec.*,
        key.base.roundedness,
        0,
        key.base.border_width,
        key.base.border_color
    );

    key.center.x = rec.x + (rec.width / 2);
    key.center.y = rec.y + (rec.height / 2);

    const text_pos = key.center;

    // Origin is the point within the text that gets placed at text_pos
    // We want the center of the text to be at that position
    const origin = Vec2{
        .x = text_size.x / 2,
        .y = text_size.y / 2,
    };

    rl.drawTextPro(
        key.base.font.*,
        key_name,
        Vec2{ .x = text_pos.x + 1, .y = text_pos.y + 1 },
        origin,
        key.base.text_angle,
        key.base.font_size,
        1.0,
        rl.Color{ .r = 0, .g = 0, .b = 0, .a = 200 }
    );

    rl.drawTextPro(
        key.base.font.*,
        key_name,
        text_pos,
        origin,
        key.base.text_angle,
        key.base.font_size,
        1.0,
        key.base.text_color
    );
    rec.x += key.base.right_padding;
}

fn drawKeys(keys: *Keys, x_start: f32, y_start: f32, default: *const BaseKey) void {
    const space: f32 = default.width * 0.15;
    var rec = Rectangle{
        .height = default.height,
        .width = default.width,
        .x = x_start,
        .y = y_start,
    };

    var key_name_buf: [64:0]u8 = undefined;
    var i: usize = 0;
    for (keys.keys) |*key| {
        if (i != key.row) {
            if (i == 0) {
                rec.y += default.height + (default.height * 0.5);
            } else {
                rec.y += default.height + space;
            }
            rec.x = x_start;
        }
        const key_name = stats.UsbHidKey.getLabel(key.usb_id);
        @memcpy(key_name_buf[0..key_name.len], key_name);
        key_name_buf[key_name.len] = 0;
        const text_size: Vec2 = rl.measureTextEx(
            key.base.font.*,
            key_name_buf[0..key_name.len :0],
            key.base.font_size,
            1
        );

        drawKey(key, &rec, text_size, key_name_buf[0..key_name.len :0]);
        i = key.row;
    }
}

fn renderHeatMap(
    layout: *Keys,
    typing_stats: *stats.TypingStats,
    heatmap_shader: rl.Shader,
    heatmap_target: rl.RenderTexture2D,
    default: *const BaseKey
) void {
    var max_vec: @Vector(VEC32_WIDTH, u32) = @splat(0);
    var min_vec: @Vector(VEC32_WIDTH, u32) = @splat(std.math.maxInt(u32));
    var i: usize = 0;

    while (i + VEC32_WIDTH <= typing_stats.unigrams.len) : (i += VEC32_WIDTH) {
        const chunk: @Vector(VEC32_WIDTH, u32) = typing_stats.unigrams[i..][0..VEC32_WIDTH].*;
        max_vec = @max(max_vec, chunk);
        min_vec = @min(min_vec, chunk);
    }

    var max_scalar: u32 = 0;
    var min_scalar: u32 = 0;
    for (0..VEC32_WIDTH) |j| {
        max_scalar = @max(max_scalar, max_vec[j]);
        min_scalar = @min(min_scalar, min_vec[j]);
    }

    while (i < typing_stats.unigrams.len) : (i += 1) {
        max_scalar = @max(max_scalar, typing_stats.unigrams[i]);
        min_scalar = @min(min_scalar, typing_stats.unigrams[i]);
    }

    const sqrt_min = std.math.sqrt(@as(f32, @floatFromInt(min_scalar)));
    const sqrt_max = std.math.sqrt(@as(f32, @floatFromInt(max_scalar)));
    const sqrt_range = if (sqrt_max > sqrt_min) sqrt_max - sqrt_min else 1.0;

    rl.beginTextureMode(heatmap_target);
    rl.clearBackground(rl.Color{ .r = 0, .g = 0, .b = 0, .a = 255 });

    rl.beginBlendMode(rl.BlendMode.additive);
    for (layout.keys) |*key| {
        const key_press_count = typing_stats.unigrams[@intCast(@intFromEnum(key.usb_id))];
        if (key_press_count == 0) continue;

        const sqrt_value = std.math.sqrt(@as(f32, @floatFromInt(key_press_count)));

        const normalized = (sqrt_value - sqrt_min) / sqrt_range;
        const alpha: u8 = @intFromFloat(normalized * 255.0);

        const radius = default.width * 1.05;
        const iters: usize = @intFromFloat(@round(key.base.width / default.width));

        var cur_center = key.center;
        const add_width: f32 = key.base.width / @as(f32, @floatFromInt(iters));
        cur_center.x = key.center.x - (key.base.width * 0.5) + (add_width * 0.5);
        for (0..iters) |_| {
            rl.drawCircleGradient(
                @intFromFloat(cur_center.x),
                @intFromFloat(cur_center.y),
                radius,
                rl.Color{ .r = 255, .g = 255, .b = 255, .a = alpha },
                rl.Color{ .r = 255, .g = 255, .b = 255, .a = 0 }
            );
            cur_center.x += add_width;
        }
    }
    rl.endBlendMode();
    rl.endTextureMode();

    rl.beginShaderMode(heatmap_shader);
    rl.drawTextureRec(
        heatmap_target.texture,
        rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(heatmap_target.texture.width),
            .height = @floatFromInt(-heatmap_target.texture.height)
        },
        Vec2{ .x = 0, .y = 0 },
        Color.white
    );

    rl.endShaderMode();
}

pub fn main() !void {
    var buffer: [1024 * 16]u8 = undefined; // 8 KB
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var arena = std.heap.ArenaAllocator.init(fba.allocator());
    // defer arena.deinit(); No need
    const allocator = arena.allocator();

    var typing_stats: stats.TypingStats = try stats.TypingStats.init();
    defer typing_stats.saveAll();

    const screen_width = 1920;
    const screen_height = 72 * 6 + 128;
    const flags = rl.ConfigFlags{
        .vsync_hint = true,
        .msaa_4x_hint = true,
        .window_highdpi = true
    };
    rl.setConfigFlags(flags);
    rl.initWindow(screen_width, screen_height, "Key logging");
    //rl.setWindowIcon();

    // Shaders
    // const shader = rl.loadShader(null, "resources/shaders/heatmap.fsh") catch |err| {
        // std.debug.print("Failed to load shader: {}\n", .{err});
        // return error.ShaderFailedLoad;
    // };
    const shader = rl.loadShaderFromMemory(null, shader_content.heatmap_shader) catch |err| {
        std.debug.print("Failed to load shader: {}\n", .{err});
        return error.ShaderFailedLoad;
    };
    const target = try rl.loadRenderTexture(screen_width, screen_height);

    var hook = try pf.install(&recordKeyEvent, &typing_stats);
    defer pf.uninstall(&hook);
    rl.setTargetFPS(60);

    const default_font = try rl.getFontDefault();

    const default = BaseKey{
        .width = 72,
        .height = 72,
        .angle = 0,
        .right_padding = 72 + (72 * 0.15), // width + space
        .roundedness = 0.25,
        .text_angle = 0,
        .text_color = .white,
        .bg_color = .black,
        .border_color = .fromInt(0x5D57A4),
        .border_width = 3,
        .font_size = 20,
        .font = &default_font
    };

    var layout = Keys.initAnsiKeyboard(allocator, &default) catch |err| switch (err) {
        else => {
            std.debug.print("Invalid layout - {}\n", .{err});
            return;
        },
    };

    while (!rl.windowShouldClose()) {
        pf.pollEvents();
        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);
        
        if (rl.isKeyDown(rl.KeyboardKey.p)) {
            typing_stats.print();
        }

        if (rl.isKeyDown(rl.KeyboardKey.s)) {
            try typing_stats.saveAndResetAll();
        }

        if (rl.isKeyDown(rl.KeyboardKey.f1)) {
            for (0x04..0x1E) |i| {
                if ((i - 0x04) % 5 == 0) {
                    std.debug.print("\n", .{});
                }
                const key: u8 = @intCast(i);
                std.debug.print("{s}: {d}, ", .{
                    stats.UsbHidKey.getName(@enumFromInt(key)),
                    typing_stats.unigrams[i]
                });
            }
        }


        renderHeatMap(&layout, &typing_stats, shader, target, &default);
        drawKeys(&layout, 25, 25, &default);

        //rl.drawRectangle(posX: i32, posY: i32, width: i32, height: i32, color: Color)

        //rl.drawText(rl.getKeyPressed(), 480, 270, 18, rl.Color.white);
        rl.endDrawing();
    }
}
