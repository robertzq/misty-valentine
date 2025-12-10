import os
from PIL import Image

# ================= 配置区域 =================
# 1. 把这里改成你那张画的实际文件名 (支持 jpg, png 等)
IMAGE_FILENAME = "UlaPic.jpg" 

# 2. 输出文件夹的名字
OUTPUT_FOLDER = "painting_parts"
# ===========================================

def slice_image():
    # 获取当前脚本所在的路径
    current_dir = os.path.dirname(os.path.abspath(__file__))
    image_path = os.path.join(current_dir, IMAGE_FILENAME)
    output_dir = os.path.join(current_dir, OUTPUT_FOLDER)

    print(f"正在读取图片: {image_path}")

    # 1. 打开图片
    try:
        img = Image.open(image_path)
    except FileNotFoundError:
        print(f"❌ 错误：找不到文件 '{IMAGE_FILENAME}'")
        print("请确认图片和脚本在同一个文件夹里，且名字写对了！")
        return

    # 2. 准备输出文件夹
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"📂 创建文件夹: {OUTPUT_FOLDER}")

    width, height = img.size
    piece_width = width // 3
    piece_height = height // 3

    print(f"🖼️ 图片尺寸: {width}x{height}")
    print(f"✂️ 切割尺寸: {piece_width}x{piece_height} (3x3 九宫格)")

    # 3. 开始切割
    count = 1
    for row in range(3):
        for col in range(3):
            left = col * piece_width
            upper = row * piece_height
            right = left + piece_width
            lower = upper + piece_height

            # 切割并保存
            piece = img.crop((left, upper, right, lower))
            
            save_name = f"part_{count}.png"
            save_path = os.path.join(output_dir, save_name)
            piece.save(save_path)
            
            print(f"✅ 生成: {save_name}")
            count += 1

    print(f"\n🎉 搞定！切好的图片都在 '{OUTPUT_FOLDER}' 文件夹里了。")
    print("👉 下一步：把这个文件夹直接拖进 Godot 的 assets/textures 里。")

if __name__ == "__main__":
    slice_image()
