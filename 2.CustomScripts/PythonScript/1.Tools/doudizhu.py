from InputClean.InputClean import ci
from os import system
from numpy import sum as npsum
from numpy import array, max, where
from re import compile, findall, search

def red(msg: str) -> None:
    return f"\033[91m{msg}\033[0m"

def green(msg: str) -> None:
    return f"\033[92m{msg}\033[0m"

def yellow(msg: str) -> None:
    return f"\033[93m{msg}\033[0m"

def cyan(msg: str) -> None:
    return f"\033[96m{msg}\033[0m"

def check_name(msg: str) -> None:
    if len(msg) > 5:
        msg = f"{msg[:4]}.."
    return msg

def view_history(game_list: list, status_list: list, players: list) -> None:
    system("clear")
    gl = game_list[1:]
    sl = status_list[1:]
    line = "---------------------------------------"
    print(line)
    for index, (points, info) in enumerate(zip(gl, sl)):
        dizhu_player = players[info[0]]
        dizhu_win = info[1]
        qinagdizhu = info[2]
        boom = info[3]
        print(f"第{yellow(index + 1)}局：")
        print(f"地主：{dizhu_player}, 地主 {green('胜') if dizhu_win else red('负')}")
        print("-+-+-+-")
        print(f"抢地主回数: {qiangdizhu},")
        print(f"炸弹个数: {boom}")
        print("-+-+-+-")
        for index, point in enumerate(points):
            if point >= 0:
                print(f"玩家{index}: {yellow(players[index])}\t {green(point)}")
            else:
                print(f"玩家{index}: {yellow(players[index])}\t {red(point)}")
        print(line)
    input("输入任意键返回对局...")

def input_safe_num(msg: str, length: int, range_: list = None) -> int | str:
    inputer = ci(msg)
    if len(inputer) == 1 and inputer in {"h", "H", "e", "E"}:
        return inputer
        
    while len(inputer) > length:
        inputer = ci(f"您的输入过长，请重新输入\n{msg}")
    while len(compile(r'\D').findall(inputer)) != 0:
        inputer = ci(f"您的输入包含非数字，请重新输入\n{msg}")
    while inputer == "":
        inputer = ci(f"您不能直接输入回车，请重新输入\n{msg}")
    if range_ != None:
        if int(inputer) not in range_:
            print(f"您只能输入{range_}中的数字，请重新输入")
            inputer = input_safe_num(msg, length, range_)
    return int(inputer)

def sum_games(game_list: list, max_: int) -> list:
    result = [0, 0, 0]
    for index, game in enumerate(game_list):
        if index > max_:
            break
        result = npsum([result, game], axis=0).tolist()
    return result

exit_flag = False
while not exit_flag:
    system("clear")
    print("powered by 折木凛曦")
    print(f"{'-' * 20}")
    print(f"{green('斗地主积分器')}")
    print("---")
    print("* 开始记录游戏：任意键开始\n* 退出：输入 e+回车")
    print(f"{'-' * 20}")
    select = ci("输入 > ")
    if select in {"e", "E"}:
        exit(0)
    system("clear")
    print(f"{green('==== 本局基本设定 ====')}")
    player_list = []
    for player in range(3):
        temp = check_name(ci(f"玩家{player}昵称: "))
        while temp in player_list:
            print("玩家昵称已存在，请输入其他昵称")
            temp = check_name(ci(f"玩家{player}昵称: "))
        player_list.append(temp)
        print()
    base_point = input_safe_num("几块的局？（请输入数字）：", 15)

    game_list = [[0, 0, 0]]
    # 0: 地主玩家 1: 地主胜负 2: 抢地主次数 3: 炸弹个数
    status_list = [[0, 0, 0, 0]]
    game_counter = 1
    while True:
        system("clear")
        latest_point = game_list[game_counter - 1]
        print(f"{cyan('现在游戏')}： 第{yellow(f'{game_counter:02}')}场 ({yellow(base_point)}块局)")
        print("---------------------------------------")
        for index, point in enumerate(sum_games(game_list, len(game_list))):
            player = player_list[index]
            print(f"{yellow(f'玩家{index}')} : {yellow(player)}\t ", end="")
            if point < 0:
                print(f"{red(point)}")
            else:
                print(f"{green(point)}")
        print("---------------------------------------")
        print(" * 查看本局得分历史记录请输入 - h")
        print(" * 结束本局请输入 - e")
        print(" # 以上命令请直接在下方本场胜者的地方输入。")
        print(" # 如果出现输入错误的情况请继续输入完4个项目，")
        print("   最后选择重新输入即可。")
        print("---------------------------------------")
        player_win = input_safe_num("本场胜者(输入玩家编号数字)：", 1, [i for i in range(3)])
        if type(player_win) is str:
            if player_win.upper() == "H":
                view_history(game_list, status_list, player_list)
                continue
            if player_win.upper() == "E":
                system("clear")
                latest_point = array(sum_games(game_list, len(game_list)))
                max_players = where(latest_point == max(latest_point))[0]
                print("-+-+-+-+-+-+-+-+-+-+-+-+-")
                print(f"对局结束，最高点数者： ")
                for player in max_players:
                    print(f"{player_list[player]}, ", end="")
                print("\n-+-+-+-+-+-+-+-+-+-+-+-+-")
                print("各玩家点数：")
                for player in range(len(player_list)):
                    print(f"{yellow(f'玩家{player}')} : {yellow(player_list[player])}\t ", end="")
                    if latest_point[player] < 0:
                        print(f"{red(latest_point[player])}")
                    else:
                        print(f"{green(latest_point[player])}")
                print("-+-+-+-+-+-+-+-+-+-+-+-+-")
                input("输入任意键返回主页面...")
                break
        dizhu_player = input_safe_num("谁是地主？(输入玩家编号数字)：", 1, [i for i in range(3)])
        qiangdizhu = input_safe_num("抢了几回地主？：", 1)
        boom = input_safe_num("本场有几个炸弹？：", 2)
        confirmed_input = ci("\n确认以上输入吗？\n * 重新输入：r+回车\n * 确认输入：直接回车或者任意键回车\n>> ")
        if len(confirmed_input) == 1 and confirmed_input in {"r", "R"}:
            continue
        
        # cal point
        point = base_point
        if qiangdizhu != 0 or boom != 0:
            for _ in range(qiangdizhu):
                point *= 2
            for _ in range(boom):
                point *= 2
        
        now_point = []
        for player in range(len(player_list)):
            if player_win != dizhu_player:
                if player == dizhu_player:
                    now_point.append(-point*2)
                else:
                    now_point.append(point)
            else:
                if player == dizhu_player:
                    now_point.append(point*2)
                else:
                    now_point.append(-point)
        game_list.append(now_point)
        status_list.append([dizhu_player, dizhu_player==player_win, qiangdizhu, boom])
        game_counter += 1