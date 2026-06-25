import os

def pack_project_code(output_filename='all_code.txt'):
    """
    遍历当前目录下的所有代码文件，整合到一个txt文件中。
    会自动忽略构建目录、资源目录和隐藏文件夹。
    """
    
    # 获取脚本所在的当前目录
    root_dir = os.getcwd()
    
    # 配置：需要抓取的文件后缀 (根据您的项目是 Flutter 还是 原生 Android 修改)
    # 这里配置的是 Flutter + Android 混合的常见后缀
    target_extensions = {
        '.dart',        # Flutter 核心逻辑
        '.yaml',        # 配置文件 (pubspec.yaml)
        '.xml',         # Android 清单文件等
        '.gradle',      # 构建脚本
        '.properties',  # 属性配置
        '.kt',          # Kotlin 代码
        '.java'         # Java 代码
    }

    # 配置：需要彻底忽略的目录 (黑名单)
    ignore_dirs = {
        '.git', 
        '.idea', 
        '.dart_tool', 
        '.gradle', 
        'build', 
        'ios',          # 如果不调试 iOS 可忽略
        'web', 
        'macos', 
        'linux', 
        'windows',
        'test',         # 如果不需要测试代码可忽略
        'assets',       # 图片资源通常不需要文本化
        'images'
    }

    print(f"开始扫描项目: {root_dir} ...")
    
    file_count = 0
    
    with open(output_filename, 'w', encoding='utf-8') as out_f:
        # 添加头部说明
        out_f.write("Project Code Export\n")
        out_f.write("===================\n\n")

        for subdir, dirs, files in os.walk(root_dir):
            # 1. 过滤掉黑名单目录 (修改 dirs 列表会影响 os.walk 的后续遍历)
            dirs[:] = [d for d in dirs if d not in ignore_dirs]
            
            for file in files:
                # 跳过输出文件本身和脚本本身
                if file == output_filename or file == os.path.basename(__file__):
                    continue
                
                # 检查后缀名
                ext = os.path.splitext(file)[1]
                if ext in target_extensions:
                    file_path = os.path.join(subdir, file)
                    rel_path = os.path.relpath(file_path, root_dir)
                    
                    try:
                        with open(file_path, 'r', encoding='utf-8') as in_f:
                            content = in_f.read()
                            
                        # 写入分隔符和文件名，方便 AI 识别
                        out_f.write(f"\n{'='*60}\n")
                        out_f.write(f"--- FILE: {rel_path} ---\n")
                        out_f.write(f"{'='*60}\n")
                        out_f.write(content)
                        out_f.write("\n")
                        
                        file_count += 1
                        print(f"已添加: {rel_path}")
                        
                    except Exception as e:
                        print(f"[跳过] 无法读取文件 {rel_path}: {e}")

    print(f"\n完成！共整合了 {file_count} 个文件。")
    print(f"请将生成的文件 '{output_filename}' 发送给我。")

if __name__ == '__main__':
    pack_project_code()