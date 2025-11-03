const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&stdout_buffer);
    const output = &stdout.interface;

    const number = getInput(output) catch |err| {
        return std.debug.print("Invalid number: {}\n", .{err});
    };

    const string = i32ToString(allocator, number) catch |err| {
        return std.debug.print("Failed to convert number {d} to string: {}\n", .{number, err});
    };

    _ = formatString(allocator, string, output) catch |err| {
        return std.debug.print("Failed to format the number '{s}': {}\n", .{string, err});
    };
}

fn getInput(output: *std.io.Writer) !i32 {
    var stdin_buffer: [1024]u8 = undefined;

    var stdin = std.fs.File.stdin().reader(&stdin_buffer);

    var line_buffer: [1024]u8 = undefined;
    var w: std.io.Writer  = .fixed(&line_buffer);

    try output.writeAll("Please enter your number: ");
    try output.flush();

    const line_length = try stdin.interface.streamDelimiterLimit(&w, '\n', .unlimited);
    const input_line = line_buffer[0..line_length];

    return std.fmt.parseInt(i32, input_line, 10);
}

fn i32ToString(allocator: std.mem.Allocator, number: i32) ![]u8 {
    const num_len = std.math.log10(@abs(number))+1;
    const string = try allocator.alloc(u8, num_len);

    return std.fmt.bufPrint(string, "{}", .{number});
}

fn formatString(allocator: std.mem.Allocator, ex_string: []u8, output: *std.io.Writer) !void {
    if (ex_string.len <= 4) {
        try output.print("{s}\n", .{ex_string});
        return;
    }
    const step = 3;

    var decimal_points = ex_string.len / step;
    if (ex_string.len % step == 0) decimal_points -= 1;

    const dec_pts_arr = try allocator.alloc(i32, decimal_points);
    defer allocator.free(dec_pts_arr);

    var j: i32 = @as(i32, @intCast(ex_string.len)) - 1 - step;
    var it: usize = 0;
    while (j >= 0) : (j -= step) {
        dec_pts_arr[it] = j;
        it += 1;
    }

    for (0.., ex_string) |i, char| {
        var sign: u8 = 0;
        for (dec_pts_arr) |dec| {
            if (dec == i) {
                sign = ',';
                break;
            }
        }

        try output.print("{c}{c}", .{char, sign});
    }

    try output.print("\n", .{});
    try output.flush();
}