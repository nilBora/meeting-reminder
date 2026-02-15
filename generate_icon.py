#!/usr/bin/env python3
"""Generate app icon for Meeting Reminder."""

from PIL import Image, ImageDraw, ImageFont
import math
import os

SIZE = 1024
CENTER = SIZE // 2
ASSETS_DIR = "MeetingReminder/Resources/Assets.xcassets/AppIcon.appiconset"


def draw_icon(size=SIZE):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    margin = size * 0.08
    r = size * 0.18  # corner radius

    # Background: deep night ocean gradient
    for y in range(size):
        t = y / size
        # Gradient from #0f172a → #1e293b with a subtle blue-cyan tint
        r_c = int(15 + t * 20)
        g_c = int(23 + t * 25)
        b_c = int(42 + t * 30)
        draw.rectangle([0, y, size, y + 1], fill=(r_c, g_c, b_c, 255))

    # Create rounded rectangle mask
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    ri = int(r)
    mask_draw.rounded_rectangle(
        [int(margin), int(margin), int(size - margin), int(size - margin)],
        radius=ri,
        fill=255,
    )

    # Apply mask to background
    bg = img.copy()
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    img.paste(bg, mask=mask)
    draw = ImageDraw.Draw(img)

    # Inner area bounds
    x0 = margin
    y0 = margin
    x1 = size - margin
    y1 = size - margin
    w = x1 - x0
    h = y1 - y0
    cx = (x0 + x1) / 2
    cy = (y0 + y1) / 2

    # Draw subtle glow in center
    for i in range(80, 0, -1):
        alpha = int(3 * (80 - i) / 80)
        glow_r = int(w * 0.25 * i / 80)
        glow_color = (34, 211, 238, alpha)  # cyan glow
        draw.ellipse(
            [cx - glow_r, cy - glow_r, cx + glow_r, cy + glow_r],
            fill=glow_color,
        )

    # Calendar body
    cal_margin_x = w * 0.15
    cal_margin_top = h * 0.2
    cal_margin_bottom = h * 0.12
    cal_x0 = x0 + cal_margin_x
    cal_y0 = y0 + cal_margin_top
    cal_x1 = x1 - cal_margin_x
    cal_y1 = y1 - cal_margin_bottom
    cal_r = size * 0.06

    # Calendar shadow
    shadow_offset = size * 0.01
    draw.rounded_rectangle(
        [cal_x0 + shadow_offset, cal_y0 + shadow_offset,
         cal_x1 + shadow_offset, cal_y1 + shadow_offset],
        radius=int(cal_r),
        fill=(0, 0, 0, 80),
    )

    # Calendar background
    draw.rounded_rectangle(
        [cal_x0, cal_y0, cal_x1, cal_y1],
        radius=int(cal_r),
        fill=(30, 41, 59, 240),  # #1e293b
        outline=(50, 70, 100, 200),
        width=max(1, size // 256),
    )

    # Calendar header bar (top stripe)
    header_h = (cal_y1 - cal_y0) * 0.18
    # Draw header with rounded top corners
    draw.rounded_rectangle(
        [cal_x0, cal_y0, cal_x1, cal_y0 + header_h + cal_r],
        radius=int(cal_r),
        fill=(59, 130, 246, 255),  # #3b82f6 primary blue
    )
    # Cover the bottom rounded part
    draw.rectangle(
        [cal_x0, cal_y0 + header_h, cal_x1, cal_y0 + header_h + cal_r],
        fill=(59, 130, 246, 255),
    )
    # Restore calendar body below header
    draw.rectangle(
        [cal_x0 + 1, cal_y0 + header_h + 1, cal_x1 - 1, cal_y0 + header_h + cal_r],
        fill=(30, 41, 59, 240),
    )

    # Calendar rings (two small rounded rects on top)
    ring_w = size * 0.03
    ring_h = size * 0.07
    ring_r = size * 0.012
    ring_y_start = cal_y0 - ring_h * 0.3
    for ring_x in [cal_x0 + w * 0.2, cal_x1 - w * 0.2 - ring_w]:
        draw.rounded_rectangle(
            [ring_x, ring_y_start, ring_x + ring_w, ring_y_start + ring_h],
            radius=int(ring_r),
            fill=(148, 163, 184, 255),  # #94a3b8
        )

    # Grid lines in calendar body
    body_y0 = cal_y0 + header_h + size * 0.03
    body_y1 = cal_y1 - size * 0.03
    body_x0 = cal_x0 + size * 0.04
    body_x1 = cal_x1 - size * 0.04
    body_h = body_y1 - body_y0
    body_w = body_x1 - body_x0

    line_color = (71, 85, 105, 120)  # subtle grid
    line_w = max(1, size // 512)

    # 3 rows, 4 cols of dots/small squares to represent calendar grid
    rows = 3
    cols = 4
    dot_size = size * 0.025

    for row in range(rows):
        for col in range(cols):
            dx = body_x0 + (col + 0.5) * body_w / cols - dot_size / 2
            dy = body_y0 + (row + 0.5) * body_h / rows - dot_size / 2

            # Highlight one cell (the "meeting" day)
            if row == 1 and col == 1:
                highlight_pad = dot_size * 1.2
                draw.rounded_rectangle(
                    [dx - highlight_pad * 0.5, dy - highlight_pad * 0.5,
                     dx + dot_size + highlight_pad * 0.5, dy + dot_size + highlight_pad * 0.5],
                    radius=int(dot_size * 0.4),
                    fill=(34, 211, 238, 180),  # cyan highlight
                )
                draw.rounded_rectangle(
                    [dx, dy, dx + dot_size, dy + dot_size],
                    radius=int(dot_size * 0.3),
                    fill=(255, 255, 255, 240),
                )
            else:
                draw.rounded_rectangle(
                    [dx, dy, dx + dot_size, dy + dot_size],
                    radius=int(dot_size * 0.3),
                    fill=(148, 163, 184, 100),
                )

    # Clock badge (bottom-right corner of calendar)
    badge_r = size * 0.14
    badge_cx = cal_x1 - size * 0.02
    badge_cy = cal_y1 - size * 0.02

    # Badge shadow
    draw.ellipse(
        [badge_cx - badge_r + shadow_offset * 2, badge_cy - badge_r + shadow_offset * 2,
         badge_cx + badge_r + shadow_offset * 2, badge_cy + badge_r + shadow_offset * 2],
        fill=(0, 0, 0, 100),
    )

    # Badge background
    draw.ellipse(
        [badge_cx - badge_r, badge_cy - badge_r,
         badge_cx + badge_r, badge_cy + badge_r],
        fill=(34, 211, 238, 255),  # cyan #22d3ee
        outline=(255, 255, 255, 60),
        width=max(1, size // 256),
    )

    # Clock hands
    hand_color = (15, 23, 42, 255)  # dark
    # Hour hand (pointing to ~10 o'clock)
    hour_angle = math.radians(300)  # 10 o'clock
    hour_len = badge_r * 0.45
    hour_end_x = badge_cx + math.sin(hour_angle) * hour_len
    hour_end_y = badge_cy - math.cos(hour_angle) * hour_len
    hand_w = max(3, size // 180)
    draw.line(
        [(badge_cx, badge_cy), (hour_end_x, hour_end_y)],
        fill=hand_color,
        width=hand_w,
    )

    # Minute hand (pointing to ~12 o'clock, slightly past)
    min_angle = math.radians(355)
    min_len = badge_r * 0.6
    min_end_x = badge_cx + math.sin(min_angle) * min_len
    min_end_y = badge_cy - math.cos(min_angle) * min_len
    draw.line(
        [(badge_cx, badge_cy), (min_end_x, min_end_y)],
        fill=hand_color,
        width=max(2, size // 256),
    )

    # Center dot
    cd = size * 0.015
    draw.ellipse(
        [badge_cx - cd, badge_cy - cd, badge_cx + cd, badge_cy + cd],
        fill=hand_color,
    )

    # Small tick marks on clock
    for i in range(12):
        angle = math.radians(i * 30)
        t_inner = badge_r * 0.78
        t_outer = badge_r * 0.88
        tx0 = badge_cx + math.sin(angle) * t_inner
        ty0 = badge_cy - math.cos(angle) * t_inner
        tx1 = badge_cx + math.sin(angle) * t_outer
        ty1 = badge_cy - math.cos(angle) * t_outer
        tw = max(1, size // 400) if i % 3 != 0 else max(2, size // 300)
        draw.line([(tx0, ty0), (tx1, ty1)], fill=hand_color, width=tw)

    return img


def main():
    icon = draw_icon(1024)

    sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }

    for filename, px in sizes.items():
        resized = icon.resize((px, px), Image.LANCZOS)
        path = os.path.join(ASSETS_DIR, filename)
        resized.save(path, "PNG")
        print(f"  {filename} ({px}x{px})")

    # Update Contents.json
    contents = """{
  "images" : [
    { "filename" : "icon_16x16.png", "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "icon_16x16@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "icon_32x32.png", "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "icon_32x32@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "icon_128x128.png", "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "icon_128x128@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "icon_256x256.png", "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "icon_256x256@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "icon_512x512.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "icon_512x512@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}"""

    with open(os.path.join(ASSETS_DIR, "Contents.json"), "w") as f:
        f.write(contents)

    print("Done!")


if __name__ == "__main__":
    main()
