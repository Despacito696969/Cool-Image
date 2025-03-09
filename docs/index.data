#version 300 es
precision mediump float;

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

uniform vec2 window_size;
uniform float time;

out vec4 finalColor;

//////////////// K.jpg's Re-oriented 4-Point BCC Noise (OpenSimplex2) ////////////////
////////////////////// Output: vec4(dF/dx, dF/dy, dF/dz, value) //////////////////////

// Inspired by Stefan Gustavson's noise
vec4 permute(vec4 t) {
    return t * (t * 34.0 + 133.0);
}

// Gradient set is a normalized expanded rhombic dodecahedron
vec3 grad(float hash) {
    
    // Random vertex of a cube, +/- 1 each
    vec3 cube = mod(floor(hash / vec3(1.0, 2.0, 4.0)), 2.0) * 2.0 - 1.0;
    
    // Random edge of the three edges connected to that vertex
    // Also a cuboctahedral vertex
    // And corresponds to the face of its dual, the rhombic dodecahedron
    vec3 cuboct = cube;
    cuboct[int(hash / 16.0)] = 0.0;
    
    // In a funky way, pick one of the four points on the rhombic face
    float type = mod(floor(hash / 8.0), 2.0);
    vec3 rhomb = (1.0 - type) * cube + type * (cuboct + cross(cube, cuboct));
    
    // Expand it so that the new edges are the same length
    // as the existing ones
    vec3 grad = cuboct * 1.22474487139 + rhomb;
    
    // To make all gradients the same length, we only need to shorten the
    // second type of vector. We also put in the whole noise scale constant.
    // The compiler should reduce it into the existing floats. I think.
    grad *= (1.0 - 0.042942436724648037 * type) * 32.80201376986577;
    
    return grad;
}

// BCC lattice split up into 2 cube lattices
vec4 openSimplex2Base(vec3 X) {
    
    // First half-lattice, closest edge
    vec3 v1 = round(X);
    vec3 d1 = X - v1;
    vec3 score1 = abs(d1);
    vec3 dir1 = step(max(score1.yzx, score1.zxy), score1);
    vec3 v2 = v1 + dir1 * sign(d1);
    vec3 d2 = X - v2;
    
    // Second half-lattice, closest edge
    vec3 X2 = X + 144.5;
    vec3 v3 = round(X2);
    vec3 d3 = X2 - v3;
    vec3 score2 = abs(d3);
    vec3 dir2 = step(max(score2.yzx, score2.zxy), score2);
    vec3 v4 = v3 + dir2 * sign(d3);
    vec3 d4 = X2 - v4;
    
    // Gradient hashes for the four points, two from each half-lattice
    vec4 hashes = permute(mod(vec4(v1.x, v2.x, v3.x, v4.x), 289.0));
    hashes = permute(mod(hashes + vec4(v1.y, v2.y, v3.y, v4.y), 289.0));
    hashes = mod(permute(mod(hashes + vec4(v1.z, v2.z, v3.z, v4.z), 289.0)), 48.0);
    
    // Gradient extrapolations & kernel function
    vec4 a = max(0.5 - vec4(dot(d1, d1), dot(d2, d2), dot(d3, d3), dot(d4, d4)), 0.0);
    vec4 aa = a * a; vec4 aaaa = aa * aa;
    vec3 g1 = grad(hashes.x); vec3 g2 = grad(hashes.y);
    vec3 g3 = grad(hashes.z); vec3 g4 = grad(hashes.w);
    vec4 extrapolations = vec4(dot(d1, g1), dot(d2, g2), dot(d3, g3), dot(d4, g4));
    
    // Derivatives of the noise
    vec4 w_1 = (aa * a * extrapolations);
    vec3 w = d1 * w_1.x + d2 * w_1.y + d3 * w_1.z + d4 * w_1.w;
    vec3 v = g1 * aaaa.x + g2 * aaaa.y + g3 * aaaa.z + g4 * aaaa.w;

    vec3 derivative = -8.0 * w + v;
    
    // Return it all as a vec4
    // return vec4(derivative, dot(aaaa, extrapolations));
    return vec4(vec3(0.0f), dot(aaaa, extrapolations));
}

// Use this if you don't want Z to look different from X and Y
vec4 openSimplex2_Conventional(vec3 X) {
    
    // Rotate around the main diagonal. Not a skew transform.
    vec4 result = openSimplex2Base(dot(X, vec3(2.0/3.0)) - X);
    return vec4(dot(result.xyz, vec3(2.0/3.0)) - result.xyz, result.w);
}

// Use this if you want to show X and Y in a plane, then use Z for time, vertical, etc.
vec4 openSimplex2_ImproveXY(vec3 X) {
    
    // Rotate so Z points down the main diagonal. Not a skew transform.
    mat3 orthonormalMap = mat3(
        0.788675134594813, -0.211324865405187, -0.577350269189626,
        -0.211324865405187, 0.788675134594813, -0.577350269189626,
        0.577350269189626, 0.577350269189626, 0.577350269189626);
    
    vec4 result = openSimplex2Base(orthonormalMap * X);
    return vec4(result.xyz * orthonormalMap, result.w);
}

//////////////////////////////// End noise code ////////////////////////////////

struct Gradient {
   vec3 x_neg;
   vec3 x_pos;
   float weight;
   int oct;
   float ratio;
};

void main() {
   Gradient gradients[4] = Gradient[4](
      Gradient(vec3(0, 0.6, 0.7), vec3(0.7, 0, 0.7), 1.0f, 2, 2.0f),
      Gradient(vec3(1, 0, 0), vec3(1, 0, 1), 0.4f, 2, 1.0f), 
      Gradient(vec3(1, 1, 1), vec3(0, 1, 0), 0.2f, 2, 1.0f),
      Gradient(vec3(1, 1, 0), vec3(1, 0, 1), 1.0f, 4, 1.0f)
   );

   float SCALE = 400.0f;
   
   vec2 real_coord = fragTexCoord * window_size / SCALE;

   vec3 sum = vec3(0);
   float scale = 0.0f;

   for (int i = 0; i < 4; ++i) {
      Gradient grad = gradients[i];
      vec2 pos2 = vec2(real_coord.x, real_coord.y * grad.ratio);
      float x = 0.0f;

      {
         float scale_grad = 1.0f;
         float sum_grad = 0.0f;
         for (int oct = 0; oct < grad.oct; ++oct) {
            x += openSimplex2_ImproveXY(vec3(pos2.xy / scale_grad, float(i) * 20.0f + float(oct) * 4.0f + time * 0.2f)).w * scale_grad;
            sum_grad += scale_grad;
            scale_grad /= 1.5f;
         }
         x /= sum_grad;
      }

      float v = abs(x);
      v = pow(v, 0.5f);
      scale += v * grad.weight;
      sum += mix(grad.x_neg, grad.x_pos, (x + 1.0f) / 2.0f) * v * grad.weight;
   }
   sum /= scale;

   finalColor = vec4(sum, 1.0f);
}
