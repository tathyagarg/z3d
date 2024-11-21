all:
	~/zig/zig build-exe src/main.zig -lc -lSDL2 -femit-bin=zig-out/bin/cell -freference-trace=10
	zig-out/bin/cell
