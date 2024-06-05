from os import system, path, walk, makedirs
from re import compile
from sys import exit, platform
from os.path import isfile
from math import floor
from time import strftime, localtime, sleep
from shutil import copy, rmtree
from string import ascii_letters, digits
from random import seed, random, choice, sample

# import numpy as np
from numpy import exp
from numpy.random import default_rng
from numpy.random import seed as nrseed
from pandas import concat, DataFrame
from pandas import read_csv as rdc
from statsmodels import api as sm
from statsmodels.formula import api as smf
from InputClean.InputClean import ci


# define  input_file -> ipf
# define output_file -> opf
erro = '\033[31m[ERROR]\033[0m'
info = '\033[32m[INFO_]\033[0m'
warn = '\033[33m[WARN_]\033[0m'

red = '\033[31m'
cyan = '\033[96m'
green = '\033[92m'
white = '\033[0m'
yellow = '\033[93m'

# TODO: 要有单独使用其中的某个工具并结束的功能
# TODO: 写入log前检查其是否被占用
# original csv file : mfs_res[1]
# latest Anonymous csv file : opf

# ------------------------------------------------------
# offical Function

def agDiff(dfOR, dfAD):
    # Score A
    retOR = 0
    retOR_RD = 0
    
    for i in range(13):
        df_concat = concat([
            DataFrame(dfOR.loc[:, i].value_counts().sort_index()),
            DataFrame(dfAD.loc[:, i].value_counts().sort_index())
        ], axis=1).fillna(0)
        retOR += abs(df_concat.iloc[:, 0]).sum()
        retOR_RD += abs(df_concat.iloc[:, 0] - df_concat.iloc[:, 1]).sum()
    
    score_a = (1 - retOR_RD / retOR)
    return score_a

def corrDiff(dfOD, dfAD):
    # Score B
    sums = (dfOD.corr() - dfAD.corr()).abs().sum().sum()
    tpls = dfOD.shape[1] * dfOD.shape[1] * 2
    score_b = (1 -  sums / tpls)
    return score_b

def odds(df):
    # Score C
    model = smf.glm(
        formula='COVID ~ AGE+GENDER+RACE+INCOME+EDUCATION+VETERAN+NOH+HTN+DM+IHD+CKD+COPD+CA',
        data=df,
        family=sm.families.Binomial()
    )
    res = model.fit()

    df2 = DataFrame(
        res.params,
        columns=['Coef']
    )
    df2['OR'] = exp(res.params)
    df2['pvalue'] = res.pvalues
    
    return df2

def oddsDiff(df_orig, df_anon):
    # Score D
    da, do = df_anon, df_orig
    
    da.columns = ['AGE', 'GENDER', 'RACE', 'INCOME', 'EDUCATION', 'VETERAN',
                  'NOH', 'HTN', 'DM', 'IHD', 'CKD', 'COPD', 'CA']
    do.columns = ['AGE', 'GENDER', 'RACE', 'INCOME', 'EDUCATION', 'VETERAN',
                  'NOH', 'HTN', 'DM', 'IHD', 'CKD', 'COPD', 'CA']
    du.columns = ['AGE', 'GENDER', 'RACE', 'INCOME', 'EDUCATION', 'VETERAN',
                  'NOH', 'HTN', 'DM', 'IHD', 'CKD', 'COPD', 'CA', 'COVID']
    da['COVID'] = 1
    do['COVID'] = 1
    
    da = concat([da, du])
    do = concat([do, du])
    
    da = odds(da)['OR']
    do = odds(do)['OR']
    
    score_c = max(1- ((da - do).abs().max()) / 20, 0)
    score_d = max(1- ((da - do).abs().mean()) / 20, 0)
    
    return score_c, score_d

def age_layering_v1(ipf, opf):
    if ipf == 'help':
        h = '----\nUsage:\n'\
            'no parameters need to input.\n'\
            '----'
        print(h)
        return 0
    df = rdc(ipf, header=None)
    df.iloc[:, 0] = df.iloc[:, 0] // 10 * 10
    df.to_csv(opf, index=None, header=None)

def average_v1(ipf, opf):
    # rows
    global result_sta
    if ipf == 'help':
        h = '----\nUsage:\n'\
            'rows (str/int) : e.g: 1_2 or 1\n'\
            '----'
        print(h)
        return 0
    param_names = ['rows']
    param_types = ['str or int']
    raw = param_input(param_names, param_types)
    res, rows = raw
    if res == -1:
        global EXIT_POINT
        EXIT_POINT = -1
        return 0
    result_sta = [raw]
    
    df = rdc(ipf, header=None)
    row_list = [int(c) for c in rows.split('_')]
    
    avg = df.iloc[row_list, :].mean().astype(int)
    for i in range(len(row_list)):
        df.iloc[row_list[i]] = avg
    
    df.to_csv(opf, index=None, header=None)

def bottom2_round_v1(ipf, opf):
    # cols, epsilons
    if ipf == 'help':
        h = '----\nUsage:\n'\
            'cols     (str/int) : e.g: 1_2 or 1\n'\
            'epsilons (str/int) : e.g: 1_2 or 1\n'\
            '----'
        print(h)
        return 0
    res, cols, epsilons = param_input(['cols', 'epsilons'], ['str or int', 'str or int'])
    if res == -1:
        global EXIT_POINT
        EXIT_POINT = -1
        return 0
    
    df = rdc(ipf, header=None)
    col__list = [int(c) for c in cols.split('_')]
    chop_list = [int(c) for c in epsilons.split('_')]
    
    for i in range(len(col__list)):
        df.iloc[
            df.iloc[:, col__list[i]] <= chop_list[i],
            col__list[i]
        ] = chop_list[i]
    
    df.to_csv(opf, index=None, header=None)

def exclude_v1(ipf, opf):
    # target_rows
    if ipf == 'help':
        h = '----\nUsage:\n'\
            'target_rows (str) : e.g: 1_2_3_4_5_6_7\n'\
            '----'
        print(h)
        return 0
    res, target_rows = param_input(['target_rows'], ['str'])
    if res == -1:
        global EXIT_POINT
        EXIT_POINT = -1
        return 0
    
    df = rdc(ipf, header=None)
    exclude_row_list = [int(i) for i in target_rows.split('_')]
    df = df.drop(index=df.index[exclude_row_list])
    df.to_csv(opf, index=None, header=None)

def kanony_v1(ipf, opf):
    # cols, k
    if ipf == 'help':
        h = '----\nUsage:\n'\
            'cols (str/int) : e.g: 1_2 or 1\n'\
            'k    (int)     : e.g: 1\n'\
            '----'
        print(h)
        return 0
    res, cols, k = param_input(['cols', 'k'], ['str or int', 'int'])
    if res == -1:
        global EXIT_POINT
        EXIT_POINT = -1
        return 0
    
    def kanony(k_df, k_qi, k_k):
        return k_df.groupby(k_qi).filter(lambda x: x[0].count() >= k_k)
    
    df = rdc(ipf, header=None)
    qi = ddd([int(i) for i in cols.split('_')])
    
    anonymized_df = kanony(df, qi, int(k))
    anonymized_df.to_csv(opf, index=None, header=None)

def lap_v2(ipf, opf):
    # cols, epsilons, random_seed
    if ipf == 'help':
        h = '----\nUsage:\n'\
            'cols        (str/int) : e.g: 1_2 or 1\n'\
            'epsilons    (str/int) : e.g: 1_2 or 1\n'\
            'random_seed (int)     : e.g: 121213\n'\
            '----'
        print(h)
        return 0
    res, cols, epsilons, random_seed = param_input(
        ['cols', 'epsilons', 'random_seed'], ['str or int', 'str or int', 'int']
        )
    if res == -1:
        global EXIT_POINT
        EXIT_POINT = -1
        return 0
    
    def lap(x, eps, seed):
        # x += np.random.default_rng(seed).laplace(0, 1/eps, x.shape[0])
        x += default_rng(seed).laplace(0, 1/eps, x.shape[0])
        return ((x * 2 + 1) // 2).astype(int)

    def lapdf(dfin, lcol__list, lepss_list, SEED):
        df = dfin.copy()
        for i in range(len(cols)):
            df.iloc[:, lcol__list[i]] = lap(df.iloc[:, col__list[i]], lepss_list[i], SEED)
        return df

    SEED = int(random_seed)
    # np.random.seed(SEED)
    nrseed(SEED)
    df = rdc(ipf, header=None)
    col__list = [int(c) for c in cols.split('_')]
    epss_list = [float(e) for e in epsilons.split('_')]
    
    for i in range(len(col__list)):
        df.iloc[:, col__list[i]] = lap(
            df.iloc[:, col__list[i]], epss_list[i], SEED
            )
    df.to_csv(opf, index=None, header=None)

def nn_v1(ipf, opf):
    # rows, cols
    if ipf == 'help':
        h = '----\nUsage:\n'\
            'rows (str/int) : e.g: 1_2 or 1\n'\
            'cols (str/int) : e.g: 1_2 or 1\n'\
            '----'
        print(h)
        return 0
    res, rows, cols, num = param_input(
        ['rows', 'cols', 'num'], ['str or int', 'str or int', 'int']
        )
    if res == -1:
        global EXIT_POINT
        EXIT_POINT = -1
        return 0
    
    df = rdc(ipf, header=None)
    row_list = [int(r) for r in rows.split('_')]
    col_list = [int(c) for c in cols.split('_')]
    
    for i in range(len(col_list)):
        # df.iloc[row_list[i], col_list[i]] = 99
        df.iloc[row_list[i], col_list[i]] = num
    df.to_csv(opf, index=None, header=None)

def rr_v1(ipf, opf):
    # prob, cols, random_seed
    if ipf == 'help':
        h = '----\nUsage:\n'\
            'prob        (float)   : e.g: 1.0\n'\
            'cols        (str/int) : e.g: 1_2 or 1\n'\
            'random_seed (int)     : e.g: 121213\n'\
            '----'
        print(h)
        return 0
    res, prob, cols, random_seed = param_input(
        ['prob', 'cols', 'random_seed'], ['float', 'str or int', 'int']
        )
    if res == -1:
        global EXIT_POINT
        EXIT_POINT = -1
        return 0
    
    def rr(x, q):
        uniq = x.value_counts().index.values
        y = [i if random() < q else choice(uniq) for i in x]
        return y
    def rrdf(df, q, target):
        df2 = df.copy()
        for i in target:
            df2.iloc[:, i] = rr(df.iloc[:, i], q)
        return df2
    seed(int(random_seed))
    df = rdc(ipf, header=None)
    q = float(prob)
    target = ddd([int(t) for t in cols.split('_')])
    df2 = rrdf(df, q, target)
    df2.to_csv(opf, header=None, index=None)

def shuffle_v1(ipf, opf):
    # random_seed
    if ipf == 'help':
        h = '----\nUsage:\n'\
            'random_seed (int) : e.g: 121213\n'\
            '----'
        print(h)
        return 0
    res, random_seed = param_input(['random_seed'], ['int'])
    if res == -1:
        global EXIT_POINT
        EXIT_POINT = -1
        return 0

    df = rdc(ipf, header=None)
    df2 = df.sample(frac=1, random_state=int(random_seed))
    df2.to_csv(opf, header=None, index=None)

def top2_round_v1(ipf, opf):
    # cols, epsilons
    if ipf == 'help':
        h = '----\nUsage:\n'\
            'cols        (str/int) : e.g: 1_2 or 1\n'\
            'epsilons    (str/int) : e.g: 1_2 or 1\n'\
            '----'
        print(h)
        return 0
    res, cols, epsilons = param_input(
        ['cols', 'epsilons'], ['str or int', 'str or int']
        )
    if res == -1:
        global EXIT_POINT
        EXIT_POINT = -1
        return 0
    
    df = rdc(ipf, header=None)
    col__list = [int(c) for c in cols.split('_')]
    chop_list = [int(e) for e in epsilons.split('_')]
    
    for i in range(len(col__list)):
        df.iloc[
            df.iloc[:, col__list[i]] >= chop_list[i],
            col__list[i]
        ] = chop_list[i]
    df.to_csv(opf, header=None, index=None)

# offical function
# ------------------------------------------------------

def ddd(not_ddd_list):
    # data_de_duplication
    return list(set(not_ddd_list))

def test_s():
    ml = ['test1', 'test2', 'test3']
    pt = ['int', 'float', 'str']
    res = param_input(ml, pt)
    print(f'stdout: {res}')

def exit_tool(p1, p2):
    plf.close()
    if count == 1:
        rmtree(file_save_path)
    else:
        system(clsr);banner_(file_path=mfs_res[1])
        eva(opf, mfs_res[1])
    system(clsr)
    if platform == 'darwin':
        system("osascript -e 'tell application \"Terminal\" to close first window' & exit")
    else:
        exit(0)

def erro_countdown(sec):
    for i in range(sec, 0, -1):
        print(f'\rwait {i} sec.', end='')
        sleep(1)

def check_str(string):
    return bool(compile(r'^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$').match(string))

def check_type(string):
    if check_str(string):
        if '.' in string:
            return 'float'
        else:
            return 'int'
    else:
        if '_' in string:
            return 'str'
        else:
            return 'None'

class LibraryPathSplit:
    def __init__(self, file_path):
        random_str = ''.join(sample(ascii_letters + digits, 2))
        now_time = strftime("%Y%m%d%H%M%S", localtime())
        nr = f'{now_time}_{random_str}'

        self.file_path = f"{file_path}"
        self.nr = nr

    def root(self):
        return path.split(str(self.file_path))[0]

    def ext(self):
        return path.splitext(path.split(self.file_path)[1])[1].split('.')[-1]

    def file_name_ext(self):
        return path.split(self.file_path)[1]

    def file_name(self):
        return path.splitext(path.split(self.file_path)[1])[0]

    def file_name_mix(self):
        return f"{path.splitext(path.split(self.file_path)[1])[0]}_{self.nr}"

    def root_file_name(self):
        return f'{path.split(self.file_path)[0]}/{path.splitext(path.split(self.file_path)[1])[0]}'

    def root_file_name_mix(self):
        return f'{path.split(self.file_path)[0]}/{path.splitext(path.split(self.file_path)[1])[0]}_{self.nr}'

    def all(self):
        temp = LibraryPathSplit(self.file_path)
        return [self.file_path,
                temp.root(),
                temp.ext(),
                temp.file_name_ext(),
                temp.file_name(),
                temp.file_name_mix(),
                temp.root_file_name(),
                temp.root_file_name_mix()]

def manual_path_split(file_path):

    random_str = ''.join(sample(ascii_letters + digits, 2))
    now_time = strftime("%Y%m%d%H%M%S", localtime())
    nr = f'{now_time}_{random_str}'

    root = file_path.replace(file_path.split(backslash)[-1], '')
    file_name = file_path.replace(file_path.split(backslash)[-1].split('.')[-1], '')
    ext = file_name.split('.')[-1]

    file_name_mix = f'{file_name}_{nr}'
    no_ext = f'{root}/{file_name}'
    no_ext_mix = f'{no_ext}_{nr}'

    return [file_path, root, file_name, ext, file_name_mix, no_ext, no_ext_mix]

def multiple_file_split(msg):
    input_path = input(msg)
    file_list = []
    fail_list = []
    addr_start = -1
    addr_end = 0
    addr_flags = 0

    if input_path in {'E', 'e'}:
        system(clsr)
        system("osascript -e 'tell application \"Terminal\" to close first window' & exit")
    input_path = f'{input_path}/'
    for length in range(len(input_path)):
        if input_path[length] == '/' and addr_flags != 1:
            # print(f'DEBUG-flag-1:{addr_flags}::{length}->{addr_start}-{addr_end}')
            addr_flags = 1
            addr_start = length
        if input_path[length] == '.' and addr_flags == 1:
            # print(f'DEBUG-flag-2:{addr_flags}::{length}->{addr_start}-{addr_end}')
            addr_flags = 2
        if input_path[length:length + 2] == ' /' and addr_flags == 2:
            # print(f'DEBUG-flag-3:{addr_flags}::{length}->{addr_start}-{addr_end}')
            addr_flags = 3
            addr_end = length
        elif input_path[length:length + 2] == ' /' and addr_flags != 2:
            # print(f'DEBUG-flag-4:{addr_flags}::{length}->{addr_start}-{addr_end}')
            addr_start = 0
            addr_end = 0
            addr_flags = 0
        if addr_start != -1 and addr_end != 0 and addr_flags == 3:
            # print(f'DEBUG-flag-5:{addr_flags}::{length}->{addr_start}-{addr_end}')
            file_path = input_path[addr_start:addr_end]
            file_path = file_path.replace("\\", "")
            # print(f'DEBUG-file_path:{file_path}')
            if path.isfile(file_path) and len(file_path) > 10:
                file_list.append(file_path)
            else:
                fail_list.append(file_path)
            addr_start = 0
            addr_end = 0
            addr_flags = 0
    if not file_list:
        return [False, 'No drag-in files detected.']
    if len(file_list) > 1:
        return [False, 'Allow only one file to be dragged in.']
    return [True, file_list[0]]

def folder_file_statistic(content):
    file_list = []
    fail_list = []

    system(clsr)
    print(content)

    INPUT_PATH = input('Drag in a folder \n>> ').strip(r" ").strip(r"'").strip(r'"')
    if not path.isdir(INPUT_PATH):
        print(f'{erro}: The path you drag in is not a folder.')
        print(f'{erro}: Please make sure the path you drag in is a folder.')
        erro_countdown(3)
        (file_list, fail_list) = folder_file_statistic(content)
    else:
        for root, _, files in walk(INPUT_PATH):
            for f in files:
                file_path = path.join(root, f)
                if path.isfile(file_path):
                    file_list.append(file_path)
                else:
                    fail_list.append(file_path)
    if len(file_list) == 0:
        print(f'{warn}: folder_file_statistic \n'
              f'{warn}: No files available in this folder.\n')
        input("Press return/enter to return to the main menu.")
        return False
    return file_list, fail_list

def win_path_chk(msg):
    wpc_path = ci(msg)
    if wpc_path in {'E', 'e'}:
        system(clsr);exit(0)
    wpc_res = isfile(wpc_path)
    if wpc_res:
        return [True, wpc_path]
    else:
        return [False, 'Drag in file is not a .csv file']

def param_input(param_list, param_type):
    global station
    if len(param_list) != len(param_type):
        print(f'{erro}Inconsistent number of methods and parameters.')
        print(f'{erro}Plz connect editor.')
        exit(0)
    pi_count = 1
    list_max = len(max(param_list, key=len))
    type_max = 11 + 1 if 'str' not in param_type else 14 + 1
    formatpi = list_max + 1 if list_max >= 12 + 1 else 12 + 1
    value_temps = []
    def sub_banner():
        print(f'----')
        print(f'Method [{red}{menu_list[select - 1]}{white}] parameter input:')
        print(f'Parameter: {green}', end='')
        for p in param_list:
            print(f'{p} ', end='')
        print(f'{white}\n----')
        print(f'{cyan}No.{space * 4}Method_Name {space * (formatpi - 12)}', end='')
        print(f'Value_Type{space * (type_max - 10)}Parameter_Value{white}')
    sub_banner()
    for index in range(len(param_list)):
        mp, tp = param_list[index], param_type[index]
        while True:
            print(f'No.{pi_count if pi_count > 10 else f"0{pi_count}"}: ', end='')
            print(f'{mp}{space * (formatpi - len(mp))}', end='')
            print(f'{tp if tp != "str" else "str (e.g:1_2)"}', end='')
            type_len = len(tp) if tp != 'str' else 13
            print(f'{space * (type_max - type_len)}', end='')
            temp = input()
            str_type = check_type(temp)
            if str_type not in param_type[index]:
                print(f'{erro}: The type of the value is not')
                print(f'{erro}: the same as the specified type.')
                erro_countdown(3)
                pi_count = 1
            else:
                break
            system(clsr);banner_(True)
            sub_banner()
            for vt_data in value_temps:
                print(f'No.{pi_count if pi_count > 10 else f"0{pi_count}"}: ', end='')
                print(f"{vt_data[0]}{space * (formatpi - len(vt_data[0]))}", end='')
                print(f"{vt_data[1]}{space * (type_max - len(vt_data[1]))}", end='')
                print(f'{vt_data[2]}')
                pi_count += 1
        pi_count += 1
        value_temps.append([mp, tp, temp])
    value = [temp[2] for temp in value_temps]
    while True:
        cid = ci(f'{info}: confirm input data?[Y(es)/N(o)/E(xit)] > ')
        if cid.lower() in {'y', 'n', 'e', 'yes', 'no', 'exit', ''}:
            if cid in {'n', 'no'}:
                banner_(True)
                value = param_input(param_list, param_type)
                return value
            elif cid in {'e', 'exit'}:
                value.insert(0, -1)
                return value
            else:
                break
        else:
            print(f"{erro}: {cid} is illegal input.")
            continue
    value.insert(0, 1)
    station = [param_list, param_type, value]
    return value

def history_():
    system(clsr)
    banner_()
    print(open(param_log_file, 'r').read())
    print(f'{info}: Press return/enter back menu.');input()

def eva(adp, odp):
    ad = rdc(adp, header=None)
    od = rdc(odp, header=None)
    
    od[0] = od[0].apply(lambda x : floor(x / 10) * 10)
    ad[0] = ad[0].apply(lambda x : floor(x / 10) * 10)
    
    a, b = agDiff(od, ad), corrDiff(od, ad)
    c, d = oddsDiff(od, ad)
    print(f'ScoreA  : {a}')
    print(f'ScoreB  : {b}')
    print(f'ScoreC  : {c}')
    print(f'ScoreD  : {d}')
    print(f'Average : {(a + b + c + d) / 4}')
    print(f'{"*" * 50}')
    print(f'history:')
    print(open(param_log_file, 'r').read())
    print(f'{info}: Press return/enter exit.');input()
    with open(param_log_file, 'a+') as plfe:
        plfe.write(f'ScoreA  : {a}\nScoreB  : {b}\nScoreC  : {c}\nScoreD  : {d}\n')
        plfe.write(f'Average : {(a + b + c + d) / 4}\n')
    

def banner_(menu=False, root=None, file_path=None):
    ascii_b = ' _ ______        ______    _____           _     \n'\
              '(_)  _ \ \      / / ___|  |_   _|__   ___ | |___ \n'\
              '| | |_) \ \ /\ / /\___ \    | |/ _ \ / _ \| / __|\n'\
              '| |  __/ \ V  V /  ___) |   | | (_) | (_) | \__ \\ \n'\
              '|_|_|     \_/\_/  |____/    |_|\___/ \___/|_|___/\n'
    banner = f'\033[41;30miPWS 統合ツール \033[0;0m\n'\
             f'Powered by \033[96mTEIGI SHO\033[0m \n'\
             f'Based \033[92miPWS Offical Tools \033[0m\n'\
             f'\033[33m{"=" * 50}\n{ascii_b}\n{"=" * 50}\033[0m'
    print(banner)
    if file_path is not None:
        print(f'CSV files in use:')
        print(f'{" " * 4}root: \033[93m{root}\033[0m')
        print(f'{" " * 4}name: \033[93m{file_path}\033[0m\n{"_" * 50}')
    if menu:
        count = 0
        for ml in menu_list:
            count += 1
            print(f'{count if count >= 10 else f"0{count}"}. \033[96m{ml}\033[0m')
        print('----')

if __name__ == '__main__':
    menu_list = [
        'age_layering_v1',
        'average_v1',
        'bottom2_round_v1',
        'exclude_v1',
        'kanony_v1',
        'lap_v2',
        'nn_v1',
        'rr_v1',
        'shuffle_v1',
        'top2_round_v1',
        'history_',
        'exit_tool'
    ]
    clsr = 'clear' if platform in {'linux', 'darwin'} else 'cls'
    backslash = '/' if platform in {'linux', 'darwin'} else '\\'
    space = ' '
    EXIT_POINT = 0
    result_sta = []
    history = []
    system(clsr);banner_()
    while True:
        csv_msg = 'Drag in a .csv file (Or input [E/e] to exit)\n>> '
        uly_msg = 'Drag in utility.csv (Or input [E/e] to exit)\n>> '
        mfs_res = multiple_file_split(csv_msg) if platform in {'linux', 'darwin'} else win_path_chk(csv_msg)
        mfs_res_u = multiple_file_split(uly_msg) if platform in {'linux', 'darwin'} else win_path_chk(uly_msg)
        du = rdc(mfs_res_u[1])
        if mfs_res[0]:
            ipf = mfs_res[1]
            LPS = LibraryPathSplit(ipf)
            nt = f"{strftime('%Y_%m_%d_%H%M%S', localtime())}"
            rs = f"{''.join(sample(ascii_letters + digits, 4))}"
            file_save_path = f"{LPS.root()}{backslash}iPWS_TEST_{nt}_{rs}"
            param_log_file = f'{file_save_path}/param_log.log'
            makedirs(file_save_path)
            copy(ipf, file_save_path)
            plf = open(param_log_file, 'a+')
            plf.write(f'meta_csv_file :\n{" " * 4}{ipf}\n----\n')
        else:
            print(f'{erro}: {mfs_res[1]}')
            erro_countdown(3)
            system(clsr);banner_()
            continue
        count = 1
        while True:
            system(clsr);banner_(True, LPS.root(), LPS.file_name_ext())
            try:
                select = ci(f'Input Num (help_num can see usage. e.g. help_01) >> ')
                if 'help' in select:
                    select = int(select.split('_')[1])
                    if select > len(menu_list) - 1:
                        print(f'{erro}: Selected No. over range')
                        continue
                    globals()[menu_list[select - 1]]('help', 'help')
                    print(f'{info}: Press return/enter back menu.');input()
                    continue
                select = int(select)
            except Exception as E:
                print(E)
                print(f"{erro}: Illegal input")
                print(f"{erro}: Please enter only numbers or help_numbers")
                erro_countdown(3)
                continue
            try:
                if menu_list[select - 1] == 'history_':
                    plf.close()
                    globals()[menu_list[select - 1]]()
                    plf = open(param_log_file, 'a+')
                    continue
                if menu_list[select - 1] == 'exit_tool':
                    globals()[menu_list[select - 1]](ipf, opf)
                    break
                station = []
                write_temp = f'No.{count} [{menu_list[select - 1]}] '
                opf = f'{file_save_path}/No.{count}_{menu_list[select - 1]}.csv'
                globals()[menu_list[select - 1]](ipf, opf)
                if EXIT_POINT == -1:
                    EXIT_POINT = 0
                    continue
                plf.write(write_temp)
                history.append([count, ])
                if len(station) > 0:
                    pl, pt, vul = station
                    plf.write(f'{pl} {pt} \n{" " * len(write_temp)}{vul[1:]}\n----\n')
                else:
                    plf.write(f'\n----\n')
                system(clsr);banner_(True)
                print(f'{info}: Processing completed.')
                cc = input('continue? [Y(es)/(E)xit]>> ')
                if cc.lower() in {'e', 'exit'}:
                    # 保留接口，可以以后集成判分
                    system(clsr);banner_(file_path=mfs_res[1])
                    plf.close()
                    eva(opf, mfs_res[1])
                    system(clsr);banner_()
                    break
                ipf = opf
                count += 1
            except Exception as E:
                print(f'{erro}: {E}')
                print(f'{warn}: Press return/enter back menu.');input()
