from PIL import Image, ImageDraw
import os
from math import pi, cos, sin

def rounded_rectangle(draw, xy, corner_radius, fill):
    upper_left_point = xy[0]
    bottom_right_point = xy[1]
    
    draw.rectangle(
        [
            (upper_left_point[0], upper_left_point[1] + corner_radius),
            (bottom_right_point[0], bottom_right_point[1] - corner_radius)
        ],
        fill=fill
    )
    
    draw.rectangle(
        [
            (upper_left_point[0] + corner_radius, upper_left_point[1]),
            (bottom_right_point[0] - corner_radius, bottom_right_point[1])
        ],
        fill=fill
    )
    
    center_points = [
        (upper_left_point[0] + corner_radius, upper_left_point[1] + corner_radius),
        (bottom_right_point[0] - corner_radius, upper_left_point[1] + corner_radius),
        (upper_left_point[0] + corner_radius, bottom_right_point[1] - corner_radius),
        (bottom_right_point[0] - corner_radius, bottom_right_point[1] - corner_radius)
    ]
    
    for center_point in center_points:
        draw.pieslice(
            [
                (center_point[0] - corner_radius, center_point[1] - corner_radius),
                (center_point[0] + corner_radius, center_point[1] + corner_radius)
            ],
            0,
            360,
            fill=fill
        )

def create_app_icon(size):
    # Create a new image with gradient background
    image = Image.new('RGB', (size, size), '#FFFFFF')
    draw = ImageDraw.Draw(image)
    
    # Calculate dimensions
    padding = size // 8
    corner_radius = size // 12
    
    # Colors
    main_color = '#007AFF'  # iOS blue
    
    # Draw outer frame
    rounded_rectangle(
        draw,
        [(padding, padding), (size - padding, size - padding)],
        corner_radius,
        main_color
    )
    
    # Draw inner frame (white)
    inner_padding = padding * 2
    rounded_rectangle(
        draw,
        [(inner_padding, inner_padding), 
         (size - inner_padding, size - inner_padding)],
        corner_radius // 2,
        '#FFFFFF'
    )
    
    # Draw small center frame (blue)
    center_padding = inner_padding + (size - 2 * inner_padding) // 3
    rounded_rectangle(
        draw,
        [(center_padding, center_padding),
         (size - center_padding, size - center_padding)],
        corner_radius // 3,
        main_color
    )
    
    return image

def generate_all_sizes():
    sizes = {
        '40': 40,    # 20pt @2x
        '60': 60,    # 20pt @3x
        '58': 58,    # 29pt @2x
        '87': 87,    # 29pt @3x
        '80': 80,    # 40pt @2x
        '120': 120,  # 40pt @3x, 60pt @2x
        '180': 180,  # 60pt @3x
        '1024': 1024 # App Store
    }
    
    output_dir = 'reframe/Assets.xcassets/AppIcon.appiconset'
    os.makedirs(output_dir, exist_ok=True)
    
    for name, size in sizes.items():
        icon = create_app_icon(size)
        icon.save(f'{output_dir}/logo_size_{name}.png', 'PNG')

if __name__ == '__main__':
    generate_all_sizes() 