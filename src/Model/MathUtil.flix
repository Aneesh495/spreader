// Spreader: Container Terminal Operating System
// Pure High-Precision Floating Point and Trigonometric Utilities

pub mod Model.MathUtil {

    /// Pure Newton-Raphson square root implementation.
    pub def sqrt(x: Float64): Float64 = {
        if (x <= 0.0) 0.0
        else {
            def step(guess: Float64, iter: Int32): Float64 = {
                if (iter >= 25) guess
                else {
                    let next = 0.5 * (guess + x / guess);
                    if (Float64.abs(next - guess) < 1.0e-12) next
                    else step(next, iter + 1)
                }
            };
            step(if (x > 1.0) x else 1.0, 0)
        }
    }

    /// 3D Euclidean distance (hypotenuse).
    pub def hypot3(dx: Float64, dy: Float64, dz: Float64): Float64 =
        sqrt(dx * dx + dy * dy + dz * dz)

    /// 2D Euclidean distance (hypotenuse).
    pub def hypot2(dx: Float64, dy: Float64): Float64 =
        sqrt(dx * dx + dy * dy)

    /// Clamps a float value between lower and upper bounds.
    pub def clamp(v: Float64, low: Float64, high: Float64): Float64 = {
        if (v < low) low
        else if (v > high) high
        else v
    }

    /// Approximate sine function via Taylor series expansion.
    pub def sin(rad: Float64): Float64 = {
        let x = rad;
        let x3 = x * x * x;
        let x5 = x3 * x * x;
        let x7 = x5 * x * x;
        x - (x3 / 6.0) + (x5 / 120.0) - (x7 / 5040.0)
    }

    /// Approximate cosine function via Taylor series expansion.
    pub def cos(rad: Float64): Float64 = {
        let x = rad;
        let x2 = x * x;
        let x4 = x2 * x2;
        let x6 = x4 * x2;
        1.0 - (x2 / 2.0) + (x4 / 24.0) - (x6 / 720.0)
    }
}
