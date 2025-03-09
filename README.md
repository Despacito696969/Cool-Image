### <p align=center>Hey, kid! Wanna see a cool animated image? Here, take this: <br/>https://despacito696969.github.io/Cool-Image/</p>

Based on this cool template: https://github.com/karl-zylinski/odin-raylib-web

I was bored during the geometry of image course and had idea to code this thingy and it looks kinda cool, maybe I should add stuff to it, idk.

I also had to compile raylib myself with `-DGRAPHICS_API_OPENGL_ES3` flag or something like that because it didn't work.

Also had to add a flag to `build_web.sh` so that emcc would use WebGL2 because shader requires noise, which requires GLSL version 300 es, because of array accessing. I spent like a few hours trying to figure this stupid thing out but it's figured out which is cool I guess.
