#import "Basic";
#import "File";
#import "Random";

IMAGE_WIDTH :: 1600;
IMAGE_HEIGHT :: 900;

OUTPUT_IMAGE_PAHT :: "output.ppm";

DEFAULT_SEED_COUNT :: 20;
SEED_RADIUS :: 5;

BACKGROUND_COLOR :: 0x96c5f9ff;
SEED_COLOR :: 0x9d5dfcff;

PALETTE_COUNT :: 9;

NAYEON_COLOR :: 0xecc049ff;
JEONGYEON_COLOR :: 0x54cca3ff;
MOMO_COLOR :: 0xe37ee6ff;
SANA_COLOR :: 0xb4798cff;
JIHYO_COLOR :: 0x85ccf9ff;
MINA_COLOR :: 0xd4c771ff;
DAHYUN_COLOR :: 0xfefefeff;
CHAEYOUNG_COLOR :: 0x2227e6ff;
TZUYU_COLOR :: 0xa35322ff;

PALETTE :: u32.[NAYEON_COLOR, JEONGYEON_COLOR, MOMO_COLOR, SANA_COLOR, JIHYO_COLOR, MINA_COLOR, DAHYUN_COLOR, CHAEYOUNG_COLOR, TZUYU_COLOR]; 

image : [IMAGE_HEIGHT][IMAGE_WIDTH] u32;

seed_position :: struct {
    x: u16;
    y: u16;
};

seeds : [DEFAULT_SEED_COUNT]seed_position;

set_random_seed :: () {
    for 0..DEFAULT_SEED_COUNT - 1 {
        time_seed := cast(S128) current_time_monotonic();
        random_state := Random_State.{xx time_seed.low, xx time_seed.high};
        x := cast,no_check(u16) (random_get_within_range(*random_state, xx SEED_RADIUS, cast(float) IMAGE_WIDTH - SEED_RADIUS));
        y := cast,no_check(u16) (random_get_within_range(*random_state, xx SEED_RADIUS, cast(float) IMAGE_HEIGHT - SEED_RADIUS));
        seeds[it] = .{x, y};
    }
}

fill_seed_with_color :: (color: u32) {
    for 0..DEFAULT_SEED_COUNT - 1 {

        left_x := seeds[it].x - SEED_RADIUS;
        left_y := seeds[it].y - SEED_RADIUS;

        right_x := seeds[it].x + SEED_RADIUS;
        right_y := seeds[it].y + SEED_RADIUS;

        for j: left_y..right_y {
            for i: left_x..right_x {
                if distance_pow(xx i, xx j, xx seeds[it].x, xx seeds[it].y)  <= SEED_RADIUS * SEED_RADIUS {
                    image[j][i] = color;
                }
            }
        }

    }
}

fill_image_with_color :: (color: u32) {
    for i: 0..IMAGE_HEIGHT - 1 {
        for j: 0..IMAGE_WIDTH - 1 {
            image[i][j] = color;
        }
    }
}

distance_pow :: (x: int, y: int, x1: int, y1: int) -> int  {
    return (x1 - x) * (x1 - x) + (y1 -y) * (y1 - y);
}

render_voronoi_naive :: () {
    for j: 0..IMAGE_HEIGHT - 1 {
        for i: 0..IMAGE_WIDTH - 1 {
            k := 0;
            for 1..DEFAULT_SEED_COUNT-1 {
                if distance_pow(xx seeds[it].x, xx seeds[it].y, xx i, xx j) < distance_pow(xx seeds[k].x, xx seeds[k].y, xx i, xx j) {
                    k = it;
                }
            }
            image[j][i] = PALETTE[k%PALETTE_COUNT];
        }
    }
}

save_image_as_ppm :: (name: string) {
    file, success := file_open(name, for_writing=true);
    assert(success);

    contents := tprint("P6\n% % 255\n", IMAGE_WIDTH, IMAGE_HEIGHT);

    builder : String_Builder;

    defer free_buffers(*builder);

    append(*builder, contents);

    for i: 0..IMAGE_HEIGHT - 1 {
        for j: 0..IMAGE_WIDTH - 1 {
            // 0xAABBGGRR
            pixel := image[i][j];
            bytes := u8.[
                xx (pixel & 0x0000ff00) >> (8 * 1),
                xx (pixel & 0x00ff0000) >> (8 * 2),
                xx (pixel & 0xff000000) >> (8 * 3)];
            append(*builder, bytes.data, bytes.count);
        }
    }

    contents = builder_to_string(*builder);

    success = file_write(*file, contents.data, contents.count); 
    assert(success);
}

main :: () {
    fill_image_with_color(BACKGROUND_COLOR);
    
    set_random_seed();

    render_voronoi_naive();

    fill_seed_with_color(SEED_COLOR);

    save_image_as_ppm(OUTPUT_IMAGE_PAHT);
}
