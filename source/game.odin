package game

import rl "vendor:raylib"
import "core:c"

get_background_color :: proc() -> rl.Color {
   background_color := [3]f32{0.9, 0.2, 0.2}
   background_color_rl := rl.Color{}
   for i in 0..<3 {
      background_color_rl[i] = cast(u8) (background_color[i] * 255)
   }
   background_color_rl.a = 255
   return background_color_rl
}

rl_color_to_vec3_color :: proc(color: rl.Color) -> [3]f32 {
   result: [3]f32
   for i in 0..<3 {
      result[i] = cast(f32) color[i] / 255.0
   }
   return result
}

main :: proc() {
   for !rl.WindowShouldClose() {
      window_size := [2]f32{f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}
      rl.SetShaderValueV(shader, WINDOW_SIZE_LOC, raw_data(&window_size), .VEC2, 1)

      time_f32 := cast(f32)rl.GetTime()
      rl.SetShaderValueV(shader, TIME_LOC, &time_f32, .FLOAT, 1)

      rect_colors := [?][3]f32{
         [3]f32{1.0, 1.0, 1.0},
         [3]f32{0.6, 0.1, 0.1},
      }
      rl.SetShaderValueV(shader, RECT_COLORS_LOC, raw_data(rect_colors[:]), .VEC3, auto_cast len(rect_colors))
      
      {
      background_color := rl_color_to_vec3_color(background_color_rl)
      rl.SetShaderValueV(shader, BACKGROUND_COLOR_LOC, &background_color, .VEC3, 1)
      }

      rl.BeginDrawing()
         rl.BeginMode2D(rl.Camera2D{offset = {0, 0}, target = {0, 0}, zoom = 1, rotation = 0})
            rl.BeginShaderMode(shader)
               rl.DrawTexturePro(render_texture.texture, {0, 0, 1, 1}, {0, 0, window_size.x, window_size.y}, {0, 0}, 0, rl.WHITE)
               //rl.DrawTexture(0, 0, cast(i32)window_size.x, cast(i32)window_size.y, rl.WHITE)
            rl.EndShaderMode()
            rl.GuiColorPicker({0, 0, 150, 150}, "color :3", &background_color_rl)
         rl.EndMode2D()
      rl.EndDrawing()
   }
}

shader: rl.Shader
WINDOW_SIZE_LOC: c.int
TIME_LOC: c.int
BACKGROUND_COLOR_LOC: c.int
RECT_COLORS_LOC: c.int
background_color_rl: rl.Color
render_texture: rl.RenderTexture2D
run: bool

init :: proc() {
   run = true

   rl.SetConfigFlags({.WINDOW_RESIZABLE})
   rl.InitWindow(800, 600, "Cool Image.glsl")

   shader = rl.LoadShader(nil, "assets/shaders/shader.fs")
   WINDOW_SIZE_LOC = rl.GetShaderLocation(shader, "window_size")
   TIME_LOC = rl.GetShaderLocation(shader, "time")

   background_color_rl = get_background_color()

   render_texture = rl.LoadRenderTexture(1, 1)
}

update :: proc() {
   window_size := [2]f32{f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}
   rl.SetShaderValueV(shader, WINDOW_SIZE_LOC, raw_data(&window_size), .VEC2, 1)

   time_f32 := cast(f32)rl.GetTime()
   rl.SetShaderValueV(shader, TIME_LOC, &time_f32, .FLOAT, 1)

   rl.BeginDrawing()
      rl.BeginMode2D(rl.Camera2D{offset = {0, 0}, target = {0, 0}, zoom = 1, rotation = 0})
         rl.BeginShaderMode(shader)
            rl.DrawTexturePro(render_texture.texture, {0, 0, 1, 1}, {0, 0, window_size.x, window_size.y}, {0, 0}, 0, rl.WHITE)
         rl.EndShaderMode()
      rl.EndMode2D()
   rl.EndDrawing()
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(c.int(w), c.int(h))
}

shutdown :: proc() {
   rl.UnloadRenderTexture(render_texture)
   rl.UnloadShader(shader)
   rl.CloseWindow()
}

should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			run = false
		}
	}

	return run
}
