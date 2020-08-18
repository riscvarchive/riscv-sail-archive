#pragma once
#include "sail_state.h"

unit softfloat_f32add(sail_state *state, mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f32sub(sail_state *state, mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f32mul(sail_state *state, mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f32div(sail_state *state, mach_bits rm, mach_bits v1, mach_bits v2);

unit softfloat_f64add(sail_state *state, mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f64sub(sail_state *state, mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f64mul(sail_state *state, mach_bits rm, mach_bits v1, mach_bits v2);
unit softfloat_f64div(sail_state *state, mach_bits rm, mach_bits v1, mach_bits v2);

unit softfloat_f32muladd(sail_state *state, mach_bits rm, mach_bits v1, mach_bits v2, mach_bits v3);
unit softfloat_f64muladd(sail_state *state, mach_bits rm, mach_bits v1, mach_bits v2, mach_bits v3);

unit softfloat_f32sqrt(sail_state *state, mach_bits rm, mach_bits v);
unit softfloat_f64sqrt(sail_state *state, mach_bits rm, mach_bits v);

unit softfloat_f32toi32(sail_state *state, mach_bits rm, mach_bits v);
unit softfloat_f32toui32(sail_state *state, mach_bits rm, mach_bits v);
unit softfloat_f32toi64(sail_state *state, mach_bits rm, mach_bits v);
unit softfloat_f32toui64(sail_state *state, mach_bits rm, mach_bits v);

unit softfloat_f64toi32(sail_state *state, mach_bits rm, mach_bits v);
unit softfloat_f64toui32(sail_state *state, mach_bits rm, mach_bits v);
unit softfloat_f64toi64(sail_state *state, mach_bits rm, mach_bits v);
unit softfloat_f64toui64(sail_state *state, mach_bits rm, mach_bits v);

unit softfloat_i32tof32(sail_state *state, mach_bits rm, mach_bits v);
unit softfloat_ui32tof32(sail_state *state, mach_bits rm, mach_bits v);
unit softfloat_i64tof32(sail_state *state, mach_bits rm, mach_bits v);
unit softfloat_ui64tof32(sail_state *state, mach_bits rm, mach_bits v);

unit softfloat_i32tof64(sail_state *state, mach_bits rm, mach_bits v);
unit softfloat_ui32tof64(sail_state *state, mach_bits rm, mach_bits v);
unit softfloat_i64tof64(sail_state *state, mach_bits rm, mach_bits v);
unit softfloat_ui64tof64(sail_state *state, mach_bits rm, mach_bits v);

unit softfloat_f32tof64(sail_state *state, mach_bits rm, mach_bits v);
unit softfloat_f64tof32(sail_state *state, mach_bits rm, mach_bits v);

unit softfloat_f32lt(sail_state *state, mach_bits v1, mach_bits v2);
unit softfloat_f32le(sail_state *state, mach_bits v1, mach_bits v2);
unit softfloat_f32eq(sail_state *state, mach_bits v1, mach_bits v2);
unit softfloat_f64lt(sail_state *state, mach_bits v1, mach_bits v2);
unit softfloat_f64le(sail_state *state, mach_bits v1, mach_bits v2);
unit softfloat_f64eq(sail_state *state, mach_bits v1, mach_bits v2);
