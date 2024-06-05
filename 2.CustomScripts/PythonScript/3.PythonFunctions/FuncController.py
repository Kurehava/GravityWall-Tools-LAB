def menu_control() -> str:
    def search_func(func_name, select):
        main_func_idx = MAIN_MENU_LIST.index(func_name)
        return FUNCTION_LIST[main_func_idx][select]

    def run_func(stack, func_name):
        control_parm = globals()[func_name]()
        if control_parm == 'end':
            stack.pop()
            return stack
        if control_parm == 'menu':
            stack = ['menu']
        elif control_parm != 'again':
            if len(stack) > 1:
                select_func_name = search_func(func_name, control_parm)
            else:
                select_func_name = MAIN_MENU_LIST[control_parm]
            stack.append(select_func_name)
        stack = run_func(stack, stack[-1])
    
    stack = ['menu']
    run_func(stack, stack[-1])


if __name__ == '__main__':
    Version = 'v0.6.0_Alpha'
    MAIN_MENU_LIST = ['menu', 'func_control', 'attack', 'file_process', 'eva', 'tool', 'exit']
    FUNCTION_LIST = [
        ['匿名化処理', 'データ攻撃ツール', 'データ距離計算、置換', 'Umark評価値出力', 'ファイル処理ツール', '終了'],
        ['top', 'bottom', 'rr', 'lap', 'shuffle', 'history', 'score_details',
         'roll_back', 'return_main_menu'],
        ['attack_iloss_Umark', 'attack_iloss_Wang', 'attack_umark_distance_only', 'return_main_menu'],
        ['euclidean_distance', 'wang_distance', 'umark_distance', 'huge_wang_distance', 'record_replacement',
         'nearest_wang_distance_replacement', 'return_main_menu'],
        ['Umark'],
        ['conversion', 'return_main_menu'],
        ['exit_tool']
    ]
    PLATFORMS = {
        'darwin': {'clear': 'clear', 'backslash': '/'},
        'linux': {'clear': 'clear', 'backslash': '/'},
        'win32': {'clear': 'cls', 'backslash': '\\'}
    }
    menu_control()