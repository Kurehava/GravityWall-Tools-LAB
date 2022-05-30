import time


def change(method, left, right):
    global x, y, z
    if method == 1:
        x[left] = -1
        y[left] = -1
        z[left] = -1
    elif method == 2:
        for change_elem in range(left, right):
            x[change_elem] = -1
            y[change_elem] = -1
            z[change_elem] = -1


def ZDD(arr):
    global x, y, c, z
    special_flag = 0
    z_input = 0
    if arr == "":
        # GET_NUMBER
        z_input = input("Input binary number (8bit)\n>>")
        special_flag = 1
        for n in range(len(z_input)):
            z.append(int(z_input[n]))
    else:
        z = arr
        x = [0, 0, 0, 0, 1, 1, 1, 1]
        y = [0, 0, 1, 1, 2, 2, 3, 3]
        c = [0, 1, 2, 3, 4, 5, 6, 7]
    start = time.process_time()
    for i in range(8):
        if i % 2 == 0 and z[i + 1] == 0:  # 偶数位等于0
            change(1, i + 1, '')

    for j in range(8):  # 0000的情况
        if j % 4 == 0 and j == 0:  # 前半是0000
            if z[j] == 0 and z[j + 1] == -1 and z[j + 2] == 0 and z[j + 3] == -1:
                change(1, j + 2, '')

        elif j % 4 == 0 and j == 4:  # 后半是0000
            if z[j] == 0 and z[j + 1] == -1 and z[j + 2] == 0 and z[j + 3] == -1:
                change(1, j, '')
                change(1, j + 2, '')
            else:
                break

    print(z)
    z_input_int = []
    for n in range(len(z_input)):  # 把字符串拆分存放数组
        z_input_int.append(z_input[n])
    for n in range(len(z_input)):  # 把字符串换成int型
        z_input_int[n] = int(z_input_int[n])
    for k in range(8):  # 讨论23位00以及67位00
        if k % 4 == 2 and z_input_int[k] == 0 and z_input_int[k + 1] == 0:  # k=2 或k=6
            print("ok")
            change(1, k, '')
    print(z)

    # IF Manual Input
    if special_flag == 1:
        print("------\nPATH : ")
        for i in range(len(z)):
            if y[i] != -1:
                print(x[i], "--", y[i], "--", c[i], "--", z[i])
    # -----------------Number of path nodes statistics-----------------
    # Define Variables
    symmetries_chk = 0
    sum_path = 0
    # Symmetry detection
    # y[8] , y[0~4] = (y[4~8] - 4) ? pass , symmetries_chk += 1
    if x.count(0) == x.count(1):  # 前后是否有相同位0或1
        for arr_chk in range(0, int(len(y) / 2)):
            if y[arr_chk] != y[arr_chk + int(len(y) / 2)] - int(len(y) / 4) and y[arr_chk] != -1:
                symmetries_chk += 1
    else:
        symmetries_chk = -1
    # IF symmetries
    if symmetries_chk == 0:  #
        # ARR_ELEMENT_DELETE
        [change(1, elem_del, '') for elem_del in range(int(len(y) / 2), len(y))]
        # ARR_CHECK
        for arr_chk in range(int(len(y) / 2) - 4):  # 判断前4位#检查所有元素有没有-1
            if all(elem_chk not in {-1} for elem_chk in z[arr_chk:arr_chk + 4]) and \
                    z[arr_chk:arr_chk + 2] == z[arr_chk + 2:arr_chk + 4]:
                change(2, arr_chk + 2, arr_chk + 4)
        # SUM_PATH_ARR1
        for sum_arr1 in range(len(z)):
            if z[sum_arr1] != -1 and z.count(0) + z.count(1) > 1:
                sum_path += 1
                print('ok1')
        # SUM_PATH_Y
        for sum_y in range(1, int((len(y)) / 2)):
            if y[sum_y - 1] == y[sum_y] and y[sum_y - 1:sum_y + 1].count(-1) == 0 and y.count(-1) != len(y) - 2:
                sum_path += 1
                print('ok2')
    # IF NOT symmetries
    else:
        # ARR_CHECK
        for arr_chk in range(len(z) - 4):
            if all(elem_chk not in {-1} for elem_chk in z[arr_chk:arr_chk + 4]) and \
                    z[arr_chk:arr_chk + 2] == z[arr_chk + 2:arr_chk + 4]:
                change(2, arr_chk + 2, arr_chk + 4)
        # SUM_PATH_X
        if x.count(1) >= 2 and x.count(0) >= 2:
            sum_path += 2
            print('ok3')
        elif x.count(1) < 2 or x.count(0) < 2:
            sum_path += 1
            print('ok4')

        for arr_chk in range(0, len(y), 2):
            if len(set(y[arr_chk:arr_chk + 2])) == 1 and y[arr_chk:arr_chk + 2].count(-1) == 0:
                for arr_chk_sub in range(arr_chk + 2, len(z), 2):
                    if z[arr_chk_sub:arr_chk_sub + 2] == z[arr_chk:arr_chk + 2] and z[
                                                                                    arr_chk_sub:arr_chk_sub + 2].count(
                            -1) == 0:
                        change(2, arr_chk_sub, arr_chk_sub + 2)
                        sum_path += 1
                        print('ok5')
        # SUM_PATH_ARR1
        for sum_arr1 in range(len(x)):
            if z[sum_arr1] != -1:
                sum_path += 1
                print('ok6')
        # SUM_PATH_Y
        sum_y_chk = []
        for y_count in range(len(y)):
            if y.count(y[y_count]) == 2 and y[y_count] != -1 and sum_y_chk.count(y[y_count]) == 0:
                sum_path += 1
                sum_y_chk.append(y[y_count])
                print('ok7')
        # -----------------Number of path nodes statistics-----------------

    # IF Manual Input
    if special_flag == 1:
        print("------\nLEAF NUM :", z.count(1) + z.count(0))
        print("SUM PATH :", sum_path)
        print("SUM NODE :", int(sum_path / 2))
        end = time.process_time()
        print('------\nCPU Process time : %e s\n------' % float(end - start))
    return sum_path, int(sum_path / 2), z.count(1) + z.count(0)


if __name__ == "__main__":
    x = [0, 0, 0, 0, 1, 1, 1, 1]
    y = [0, 0, 1, 1, 2, 2, 3, 3]
    c = [0, 1, 2, 3, 4, 5, 6, 7]
    z = []
    ZDD("")
