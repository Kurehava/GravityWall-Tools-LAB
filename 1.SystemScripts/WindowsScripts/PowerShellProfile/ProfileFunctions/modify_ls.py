
import sys

from os import walk, listdir, stat
from os.path import isdir, isfile, join, getsize, exists

def cal_size(num):
    S = [[key, elem] for key, elem in SIZE.items() if num >= elem][-1]
    # S = S[-1] if len(S) else ["\033[96mbit\033[0m", num]
    # return S if S[0] not in SIZE else [S[0], round(num / S[-1], 2), color[]]
    return [S[0], round(num / 1, 2) if not S[1] else round(num / S[1], 2), COLOR[S[0]]]

def floder_size(path, size=0):
    global SIGNAL_FLAG
    for root, _, file in walk(path):
        for fn in file:
            fjrf = join(root, fn)
            try:
                add = getsize(fjrf) if exists(fjrf) else 0
            except FileNotFoundError:
                add = 0
            finally:
                size += add
                SIGNAL_FLAG = 1 if not add else 0
                
    return cal_size(size)

if __name__ == "__main__":
    bit = 0
    KB = 1024
    MB = 1024 ** 2
    GB = 1024 ** 3
    TB = 1024 ** 4

    COLOR = {"bit":90, "KB":96, "MB":93, "GB":91, "TB":95}
    SIZE = {"bit":bit, "KB":KB, "MB":MB, "GB":GB, "TB":TB}
    SIGNAL_FLAG = 1
    
    option = None
    path = sys.argv[1].replace("\\", "/")
    if len(sys.argv) > 2:
        option = sys.argv[2]

    if option is not None: 
        print("Mode      Size         File         ")
        print("-------   ----------   -----------  ")
    else:
        print("Mode      File         ")
        print("-------   -----------  ")
    
    left_space = 10
    right_space = 14 + 8 # 8 color str

    for fn in listdir(path):
        if isdir(fn):
            signal = "" if not SIGNAL_FLAG else "?"
            chmod = oct(stat(fn).st_mode)[-3:]
            if option == "-size":
                unit, size, color = floder_size(fn)
                unit_size = f"\033[{color}m{size}{signal}{' ' * (7 - len(str(size) + signal))}{unit}\033[0m"
                len_unit = len(str(unit_size))
            len_chmod = len(str(chmod))
            if " " in fn:
                if option != "-size":
                    print(f"{chmod}{' ' * (len_chmod - left_space) if len_chmod > left_space else ' ' * (left_space - len_chmod)}\033[32m'{fn}'/\033[0m")
                else:
                    print(f"{chmod}{' ' * (len_chmod - left_space) if len_chmod > left_space else ' ' * (left_space - len_chmod)}{unit_size}{' ' * (len_unit - right_space) if len_unit > right_space else ' ' * (right_space - len_unit)}\033[32m'{fn}'/\033[0m")
            else:
                if option != "-size":
                    print(f"{chmod}{' ' * (len_chmod - left_space) if len_chmod > left_space else ' ' * (left_space - len_chmod)}\033[32m{fn}/\033[0m")
                else:
                    print(f"{chmod}{' ' * (len_chmod - left_space) if len_chmod > left_space else ' ' * (left_space - len_chmod)}{unit_size}{' ' * (len_unit - right_space) if len_unit > right_space else ' ' * (right_space - len_unit)}\033[32m{fn}/\033[0m")
            SIGNAL_FLAG = 0

    for fn in listdir(path):
        if isfile(fn):
            chmod = oct(stat(fn).st_mode)[-3:]
            if option == "-size":
                unit, size, color = cal_size(getsize(fn))
                unit_size = f"\033[{color}m{size}{' ' * (7 - len(str(size)))}{unit}\033[0m"
                len_unit = len(str(unit_size))
            len_chmod = len(str(chmod))
            if ".exe" in fn:
                fn = f"\033[95m{fn}\033[0m"
            if " " in fn:
                if option != "-size":
                    print(f"{chmod}{' ' * (len_chmod - left_space) if len_chmod > left_space else ' ' * (left_space - len_chmod)}'{fn}'")
                else:
                    print(f"{chmod}{' ' * (len_chmod - left_space) if len_chmod > left_space else ' ' * (left_space - len_chmod)}{unit_size}{' ' * (len_unit - right_space) if len_unit > right_space else ' ' * (right_space - len_unit)}'{fn}'")
            else:
                if option != "-size":
                    print(f"{chmod}{' ' * (len_chmod - left_space) if len_chmod > left_space else ' ' * (left_space - len_chmod)}{fn}")
                else:
                    print(f"{chmod}{' ' * (len_chmod - left_space) if len_chmod > left_space else ' ' * (left_space - len_chmod)}{unit_size}{' ' * (len_unit - right_space) if len_unit > right_space else ' ' * (right_space - len_unit)}{fn}")
