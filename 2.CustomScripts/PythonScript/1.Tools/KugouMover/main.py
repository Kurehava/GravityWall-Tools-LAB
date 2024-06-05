import itertools
from os import walk, path, system, remove
from os.path import exists
from re import findall
from shutil import copyfile

from pydub import AudioSegment
from inputimeout_kureha_edit import inputimeout, TimeoutOccurred


def input_checker(content, input_type, input_set, re_rule=None, input_content=None):
    """
    # NAVI_INDEX = input_checker(content, 'int', {'1', '2', '3', '4', '5'}, r'[1-5]')

    Args:
        content(str): 抬头文字内容
        input_type(str): 输入内容输出时的类型
        input_set(set[str]): 输入内容的判定集合(使用字符串类型)
        re_rule(str): 判定输入内容是否合法时使用的正则规则(使用正常匹配规则,不要使用反规则)
        input_content(str): 输入时的引导语

    Returns:
        input_type: 返回指定类型的输入内容

    """

    input_check_flag = 0
    select_input_his = ''

    while True:
        system(CLEAR)
        print(content)

        if input_check_flag == 0:
            if input_content is not None:
                ic_input = input(f'{input_content} >> ').strip('"').strip(' ').strip('\'')
            else:
                ic_input = input('请输入 >> ').strip('"').strip(' ').strip('\'')
        else:
            ic_input = input(
                f'{WARN__P}: 您的输入 \033[31m{select_input_his}\033[0m 有误\n请重新输入 >> ').strip(
                '"').strip(' ').strip('\'')
            input_check_flag = 0

        # 判定是否符合re
        if re_rule is not None:
            if not findall(re_rule, ic_input):
                input_check_flag = 1
                select_input_his = ic_input
                continue

        # 判定输入值是否在集合内
        if ic_input not in input_set:
            input_check_flag = 1
            select_input_his = ic_input
        else:
            break


if __name__ == "__main__":
    # 定义抬头和彩色信息
    VERSION = 'v0.1.1'
    AUTHER_ = 'KurehaSho'
    ERROR_P = '[\033[091mERROR\033[0m]'
    WARN__P = '[\033[093mWARN-\033[0m]'
    INFO__P = '[\033[092mINFO-\033[0m]'
    NAME__P = f'\033[095m{AUTHER_}\033[0m'
    CLEAR = 'cls'

    #  Merger Conversion Tool
    title_p = "\033[42;30m Merger Conversion Tool \033[0m"
    auther_ = "\033[41;93m Powered by KurehaSho   \033[0m"

    # 到时候换成Win32 API
    # https://blog.csdn.net/weixin_44634704/article/details/123006497
    kugou_folder_path = input("KuGou Music Download Path >> ").strip(" ").strip("'").strip("\"")

    meta_file_data_base = []
    change_file_data_base = []

    for (path_, dir_list, file_list) in walk(kugou_folder_path):
        for file_name in file_list:
            meta_file_data_base.append(path.join(path_, file_name))

    while True:
        # print(f"\r开始监视酷狗下载文件夹 -- 新增{len(change_file_data_base)}个文件。", end="")
        # print("下载完成开始移动文件请按下 e和回车 。")
        # key = input("")
        try:
            key = inputimeout(prompt=f"\r开始监视酷狗下载文件夹 -- 新增{len(change_file_data_base)}个文件。", timeout=3)
        except TimeoutOccurred:
            key = 0
        if key in {"E", "e"}:
            break
        for (pr_path, pr_dir_list, pr_file_list) in walk(kugou_folder_path):
            for pr_file_name in pr_file_list:
                try:
                    meta_file_data_base.index(path.join(pr_path, pr_file_name))
                except ValueError as VE:
                    meta_file_data_base.append(path.join(pr_path, pr_file_name))
                    change_file_data_base.append(path.join(pr_path, pr_file_name))

    list_cut_tmp = []
    change_file_list_cut = []
    file_count = 0
    cut_list_length = 10

    for change_file_name in change_file_data_base:
        file_count += 1
        list_cut_tmp.append(change_file_name)
        if file_count == cut_list_length:
            change_file_list_cut.append(list_cut_tmp)
            list_cut_tmp = []
            file_count = 0
        elif file_count == len(change_file_data_base) and cut_list_length > len(change_file_data_base):
            change_file_list_cut.append(list_cut_tmp)
            list_cut_tmp = []
            file_count = 0

    print("文件筛选模式")
    print("=================")

    input_error_flag = 0
    input_error_strs = ""
    list_delete_flag = 0
    list_delete_name = ""

    while True:
        index = 0
        file_count = 1
        if index > len(change_file_list_cut) - 1:
            break
        while True:
            all_change_file_count = len(list(itertools.chain.from_iterable(change_file_list_cut)))

            for file_name in change_file_list_cut[index]:
                print(f"{file_count}. {file_name}")
            print("=================")

            if input_error_flag == 1:
                print(f"您的输入\033[31m{input_error_strs}\033[0m不正确,请重新输入。")
                input_error_flag = 0
            if list_delete_flag == 1:
                print(f"\033[32{list_delete_name}\033[0m已成功删除。")
                list_delete_flag = 0

            if index != 0:
                screen_select = input(f"预移动文件数{all_change_file_count} 文件标号)删除列表对应文件 n) 下一页 ")
                if screen_select not in {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "N", "n"}:
                    input_error_flag = 1
                    input_error_strs = screen_select
                    continue
                else:
                    file_count += 1
            elif 0 < index < len(change_file_list_cut) - 1:
                screen_select = input(
                    f"预移动文件数{all_change_file_count} 文件标号)删除列表对应文件 n) 下一页 s)上一页")
                if screen_select not in {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "N", "n", "S", "s"}:
                    input_error_flag = 1
                    input_error_strs = screen_select
                    continue
                else:
                    file_count += 1
            elif index == len(change_file_list_cut) - 1:
                screen_select = input(
                    f"预移动文件数{all_change_file_count} 文件标号)删除列表对应文件 s)上一页 w)完成开始移动")
                if screen_select not in {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "W", "w", "S", "s"}:
                    input_error_flag = 1
                    input_error_strs = screen_select
                    continue
                else:
                    file_count += 1
            else:
                screen_select = None

            if screen_select in {"S", "s"}:
                index -= 1
                break
            elif screen_select in {"N", "n"}:
                index += 1
                break
            elif screen_select in {"W", "w"}:
                index = len(change_file_list_cut)
                break
            else:
                list_delete_flag = 1
                list_delete_name = change_file_list_cut[index][int(screen_select)]
                change_file_list_cut[index].pop(int(screen_select))
                if exists(list_delete_name):
                    remove(list_delete_name)
                continue

    copy_list = list(itertools.chain.from_iterable(change_file_list_cut))
    save_folder_path = input("Music Save Path >> ").strip(" ").strip("'").strip("\"")
    music_format = {"FLAC", "OGG", "WAV"}

    copy_file_count = 0
    for meta_file_path in copy_list:
        if exists(meta_file_path) and exists(save_folder_path):
            if meta_file_path.split(".")[-1].upper() in music_format:
                music = AudioSegment.from_file(meta_file_path)
                music.export(meta_file_path.replace(f".{meta_file_path.split('.')[-1]}", "") + ".mp3", format="mp3")
                remove(meta_file_path)
            copyfile(meta_file_path, save_folder_path)
        else:
            copyfile(meta_file_path, save_folder_path)

    # TODO: 有时间找找酷狗音乐的文件保存路径的文件
    # TODO: 基本完成，将文件夹选取换用WinAPI，然后DEBUG
