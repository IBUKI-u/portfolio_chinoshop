import os
import base64
import shutil

def image_to_base64(image_path):
    """画像ファイルを読み込み、Base64エンコードされた文字列を返す"""
    with open(image_path, 'rb') as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

def convert_images_in_directory(input_dir, output_dir):
    """指定されたディレクトリ内の画像を変換し、テキストファイルと元画像を移動する"""
    # 出力先ディレクトリが存在しない場合は作成する
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"ディレクトリ {output_dir} を作成しました。")

    # 入力ディレクトリ内のファイルを一つずつ処理
    for filename in os.listdir(input_dir):
        # 画像ファイル（.png, .jpg, .jpeg）のみを対象とする
        if filename.lower().endswith(('.png', '.jpg', '.jpeg')):
            # ファイルのフルパスを取得
            original_image_path = os.path.join(input_dir, filename)
            
            # 1. 画像をBase64文字列に変換
            base64_image = image_to_base64(original_image_path)

            # 2. Base64文字列をテキストファイルとして出力先に保存
            output_txt_path = os.path.join(output_dir, f"{os.path.splitext(filename)[0]}.txt")
            with open(output_txt_path, 'w') as output:
                output.write(base64_image)
            
            # 3. 元の画像ファイルを出力先ディレクトリに移動する
            shutil.move(original_image_path, os.path.join(output_dir, filename))
            
            print(f"'{filename}' を変換し、テキストファイルと元画像を '{output_dir}' に保存しました。")

# --- メイン処理 ---
# このファイルが「直接実行された」場合にのみ、以下のコードを実行する
if __name__ == "__main__":
    # 1. このファイル(main.py)自身の絶対パスを取得
    this_file_path = os.path.abspath(__file__)

    # 2. このファイルがあるディレクトリのパスを取得
    this_dir_path = os.path.dirname(this_file_path)
    
    # 3. 入力ディレクトリと出力ディレクトリのパスを設定
    input_path = os.path.join(this_dir_path, "pre_encoded_imgs")  # 入力ディレクトリのパス（何もなければそのままで大丈夫）
    output_path = os.path.join(this_dir_path, "encoded_imgs")     # 出力ディレクトリのパス（何もなければそのままで大丈夫）

    convert_images_in_directory(input_path, output_path)
    print("\nすべての処理が完了しました。")
