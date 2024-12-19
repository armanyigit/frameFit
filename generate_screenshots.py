from PIL import Image, ImageDraw, ImageFont
import os

def create_screenshot(width, height, text, background_color='#FFFFFF'):
    # Create base image
    image = Image.new('RGB', (width, height), background_color)
    draw = ImageDraw.Draw(image)
    
    # Add text overlay
    try:
        # Try to use SF Pro Text if available (macOS)
        font = ImageFont.truetype('/System/Library/Fonts/SFProText-Bold.ttf', size=60)
    except:
        # Fallback to default font
        font = ImageFont.load_default()
    
    # Calculate text position (centered)
    text_bbox = draw.textbbox((0, 0), text, font=font)
    text_width = text_bbox[2] - text_bbox[0]
    text_height = text_bbox[3] - text_bbox[1]
    
    text_x = (width - text_width) // 2
    text_y = height - text_height - 100  # 100px from bottom
    
    # Draw text with shadow
    shadow_offset = 2
    draw.text((text_x + shadow_offset, text_y + shadow_offset), text, 
              font=font, fill='#00000022')  # Shadow
    draw.text((text_x, text_y), text, font=font, fill='#000000')  # Main text
    
    return image

def generate_screenshots():
    # iPhone 14 Pro Max dimensions (6.7")
    width = 1290
    height = 2796
    
    screenshots = [
        "Frame your photos perfectly for Instagram",
        "Select multiple photos at once",
        "Choose from Square, Portrait, or Landscape",
        "Perfect white frames every time",
        "Batch process multiple photos",
        "Save directly to your photo library"
    ]
    
    output_dir = 'AppStoreScreenshots'
    os.makedirs(output_dir, exist_ok=True)
    
    for i, text in enumerate(screenshots, 1):
        image = create_screenshot(width, height, text)
        image.save(f'{output_dir}/screenshot_{i}.png')

if __name__ == '__main__':
    generate_screenshots() 