from os.path import join, exists, dirname
from os import makedirs, listdir, system
from PIL import Image
from time import time, sleep

def create_folder_name(path: str, folder_name: str) -> str:
        temp = join(dirname(path), f"{folder_name}_{time()}")
        while exists(temp):
            temp = join(dirname(path), f"{folder_name}_{time()}")
        makedirs(temp)
        return temp

class ImgProcess():
    def __init__(self, gif_path: str, workspace: str):
        self.gif_path = gif_path
        self.workspace = workspace
    
    def split_gif2png(self) -> int:
        """split gif file frame to png file

        Returns:
            int: frame num
        """
        
        # 新建储存路径
        self.png_output = create_folder_name(self.workspace, f"split_gif2png")
        
        # 打开 GIF 文件
        gif = Image.open(self.gif_path)

        # 获取 GIF 的帧数
        num_frames = gif.n_frames

        # 创建输出文件夹
        if not exists(self.png_output):
            makedirs(self.png_output)

        # 逐帧提取并保存为 PNG
        for frame_index in range(num_frames):
            gif.seek(frame_index)
            frame = gif.copy()
            frame.save(f"{self.png_output}/frame_{frame_index:03d}.png", format="PNG")

        # 关闭 GIF 文件
        gif.close()
        
        # 返回帧数
        return num_frames

    def get_png_info(self) -> dict:
        """get png info

        Raises:
            FileNotFoundError: if can not found png_output folder, will
            output this err.

        Returns:
            dict: png infomation
        """
        
        if not self.png_output:
            raise FileNotFoundError("png folder not found.")
        with Image.open(join(self.png_output, "frame_000.png")) as img:
            self.png_info = {
                "format" : img.format,
                "mode" : img.mode,
                "width" : img.size[0],
                "height" : img.size[1],
                "info" : img.info
            }

    def check_size(self) -> bool:
        if not self.png_info:
            raise ValueError("Can not read png info.")
        
        if self.png_info["width"] > 3 * 144 or self.png_info["height"] > 5 * 144:
            pass
        elif self.png_info["width"] <= 3 * 144 or self.png_info["height"] <= 5 * 144:
            pass

def main():
    # 指定原 GIF 文件路径和输出文件夹
    gif_path = "F:\\_中转文件集\\1713779423023.gif"
    workspace = create_folder_name(dirname(gif_path), "split_workspace")
    
    # 实例化类
    pros = ImgProcess(gif_path=gif_path, workspace=workspace)

    # 调用函数并提取 GIF 的帧
    frame_num = pros.split_gif2png()

if __name__ == "__main__":
    pass