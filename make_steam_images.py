import os
from PIL import Image, ImageOps

# --- ⚙️ 配置区域 ---

# 你的截图文件名 (确保是横屏高清大图)
INPUT_IMAGE_PATH = "screenshot.png" 

# 输出文件夹
OUTPUT_DIR = "Steam_Store_Assets_HD"

# 🎯 根据你提供的最新 Steam 后台要求，精确匹配尺寸
TARGET_SIZES = {
    # --- 必填项 (Required) ---
    
    # 1. Header Capsule (页眉大图)
    # 用途：商店页面顶部、推荐列表
    "Header_Capsule": (920, 430),

    # 2. Small Capsule (小型胶囊图)
    # 用途：搜索结果列表、侧边栏
    "Small_Capsule": (462, 174),

    # 3. Main Capsule (主胶囊图)
    # 用途：首页轮播大图
    "Main_Capsule": (1232, 706),

    # 4. Vertical Capsule (竖版胶囊图)
    # 用途：特卖活动、新游列表
    "Vertical_Capsule": (748, 896),
    
    # --- 选填项 (但建议填上，不然 Steam 会自动抓图可能不好看) ---
    
    # 5. Page Background (商店页面背景)
    # Steam 会把它变暗并虚化，作为网页两侧的背景
    "Page_Background": (1438, 810),
}

# ------------------

def process_images():
    # 1. 检查文件是否存在
    if not os.path.exists(INPUT_IMAGE_PATH):
        print(f"❌ 错误：找不到文件 '{INPUT_IMAGE_PATH}'")
        return

    # 2. 创建输出文件夹
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        print(f"📁 创建文件夹: {OUTPUT_DIR}")

    try:
        with Image.open(INPUT_IMAGE_PATH) as img:
            print(f"✅ 成功打开图片: {INPUT_IMAGE_PATH} (尺寸: {img.size})")
            
            # 🛠️ 关键修复：防止 PNG 透明通道导致报错
            if img.mode in ("RGBA", "P"):
                print("ℹ️ 正在转换图片格式 (去除透明通道)...")
                img = img.convert("RGB")
            
            print("-" * 30)

            # 3. 循环裁剪生成
            for name, size in TARGET_SIZES.items():
                target_w, target_h = size
                
                # 智能算法：缩放并填满，然后裁剪掉多余边缘，保留正中心
                new_img = ImageOps.fit(img, size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))
                
                output_filename = f"{name}_{target_w}x{target_h}.jpg"
                output_path = os.path.join(OUTPUT_DIR, output_filename)
                
                new_img.save(output_path, quality=95) 
                print(f"🖼️ 已生成: {output_filename} \t(尺寸: {target_w}x{target_h})")

            print("-" * 30)
            print(f"🎉 搞定！请去 '{OUTPUT_DIR}' 文件夹里拿图上传吧。")

    except Exception as e:
        print(f"❌ 出错啦: {e}")

if __name__ == "__main__":
    process_images()