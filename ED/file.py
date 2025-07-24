import os
import shutil

# 対象の親フォルダのパス
parent_folder = "/Users/htsuk/Downloads/data"  # ← ここを自分の環境に合わせて変更

# 親フォルダ内のすべてのサブフォルダを走査
for subdir in os.listdir(parent_folder):
    subdir_path = os.path.join(parent_folder, subdir)

    if os.path.isdir(subdir_path):  # フォルダである場合のみ
        for filename in os.listdir(subdir_path):
            file_path = os.path.join(subdir_path, filename)
            dest_path = os.path.join(parent_folder, filename)

            # 同名ファイルが既にあると上書きされるので注意
            shutil.move(file_path, dest_path)

        # 空のフォルダを削除したい場合は以下を追加
        os.rmdir(subdir_path)
