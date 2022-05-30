#include<iostream>
#include<ctime>
#include<bitset>
#include<string>
#include<random>

using namespace std;

void bdd(const int *meta);

int zdd(int meta[8]);

void print_arr(const int *arr, int size);

void chg_str_arr(string str2arrs);

//global val
int z[8];
int *arrbin;

int main() {
    string strbin;
    cout << "Input STR : " << ends;
    getline(cin, strbin);
    unsigned long time_start, time_end;
    int BZCHK_FLAG = 0;
    double BDD_TIME, ZDD_TIME;
    cout << "Processing..." << endl;
    if (strbin.empty()) {
        while (true) {
            time_start = clock();
            //随机数生成
            //random_device seed_gen;
            //mt19937 e(seed_gen());
            //uniform_int_distribution<unsigned> rannum(0, 255);
            //cout << rannum(e) << endl;
            //for (int i = 0; i <= 1000000; i++) {
            for (int i = 1; i <= 255; i++) {
                //bitset<8> bitnum(rannum(e));
                bitset<8> bitnum(i);
                strbin = bitnum.to_string();
                chg_str_arr(strbin);
                cout << strbin << endl;
                if (BZCHK_FLAG == 0) {
                    bdd(arrbin);
                } else {
                    zdd(arrbin);
                }
            }
            time_end = clock();
            if (BZCHK_FLAG == 0) {
                BDD_TIME = (double) (time_end - time_start) / CLOCKS_PER_SEC;
                BZCHK_FLAG += 1;
            } else {
                ZDD_TIME = (double) (time_end - time_start) / CLOCKS_PER_SEC;
                break;
            }
        }
        cout << "COUNT CPU TIME OF BDD IS:" << BDD_TIME << endl;
        cout << "COUNT CPU TIME OF ZDD IS:" << ZDD_TIME << endl;
        cout << "Success" << endl;
    } else {
        time_start = clock();
        chg_str_arr(strbin);
        print_arr(arrbin, 8);
        bdd(arrbin);
        //zdd(arrbin);
        time_end = clock();
        BDD_TIME = (double) (time_end - time_start) / CLOCKS_PER_SEC;
        cout << "COUNT CPU TIME OF BDD IS:" << BDD_TIME << endl;
    }
    return 0;
}

void change(int *metax, int *metay, int *metaz, int method, int left, int right) {
    //@res: method1 修改三个数组中的给定下标元素为-1
    //@res: method2 修改三个数组中的给定下标范围的元素为-1
    if (method == 1) {
        metax[left] = -1;
        metay[left] = -1;
        metaz[left] = -1;
    } else {
        for (int count_index = left; count_index < right; count_index++) {
            metax[count_index] = -1;
            metay[count_index] = -1;
            metaz[count_index] = -1;
        }
    }
}

void chg_str_arr(string str2arrs) {
    int arrtran_count = 0;
    int *bin = (int *) malloc(sizeof(int) * str2arrs.length());
    for (int fc = 0; fc < str2arrs.length(); fc++) {
        bin[arrtran_count] = int(str2arrs[fc] - '0');
        arrtran_count++;
    }
    arrbin = bin;
}

int chk_func(int method, const int *arr, int y, int x) {
    //@res: method1 检测给定数组中是否存在-1
    //@res: method2 检测给定数组中元素是否全部相等
    int tran_val;
    if (method == 1) {
        for (int arr_chk = y; arr_chk < x; arr_chk++) {
            if (arr[arr_chk] == -1) {
                return 1;
            }
        }
    } else if (method == 2) {
        tran_val = arr[y];
        for (int arr_chk = y; arr_chk < x; arr_chk++) {
            if (arr[arr_chk] != tran_val) {
                return 1;
            }
        }
    }
    return 0;
}

int repeat_chk(int method, const int *meta_arr, int target, int sizes) {
    //@res: method0 遍历数组给出指定数组中target的重复元素个数
    int repeat_count = 0;
    if (method == 0) {
        for (int repeat = 0; repeat < sizes; repeat++) {
            if (meta_arr[repeat] == target) {
                repeat_count += 1;
            }
        }
    }
    return repeat_count;
}

void print_arr(const int *arr, int size) {
    //@res: 打印数组内容
    for (int count = 0; count < size; count++) {
        cout << arr[count] << ends;
    }
    cout << endl;
}

void bdd(const int *meta) {
    int x[8] = {0, 0, 0, 0, 1, 1, 1, 1};
    int y[8] = {0, 0, 1, 1, 2, 2, 3, 3};
    int c[8] = {0, 1, 2, 3, 4, 5, 6, 7};
    int change_elem, del_elem, print_elem;
    int sum_z, sum_y, sum_x_0, sum_x_1;
    int elerep_front = 0, elerep_back = 0;
    int arr_chk, arr_chk_sub;
    for (change_elem = 0; change_elem <= 7; change_elem++)
        z[change_elem] = meta[change_elem];
    int x_size = end(x) - begin(x);
    int y_size = end(y) - begin(y);
    int z_size = end(z) - begin(z);
    int half_size = int(z_size / 2);
    //Half Equality Decision
    for (int repeartchk = 0; repeartchk < half_size; repeartchk++) {
        if (z[repeartchk] != z[0])
            elerep_front = -99;
        if (z[repeartchk + half_size] != z[half_size])
            elerep_back = -99;
    }
    if (elerep_front != -99 && elerep_back != -99) {
        change(x, y, z, 2, 1, half_size);
        change(x, y, z, 2, half_size + 1, z_size);
    } else {
        if (elerep_front != -99) {
            change(x, y, z, 2, 1, half_size);
        } else if (elerep_back != -99) {
            change(x, y, z, 2, half_size + 1, z_size);
        }
    }
    //Normal
    for (arr_chk = 0; arr_chk < z_size - 1; arr_chk++) {
        if (z[arr_chk] == z[arr_chk + 1] && y[arr_chk] == y[arr_chk + 1] && z[arr_chk] != -1 && z[arr_chk + 1] != -1) {
            change(x, y, z, 1, arr_chk + 1, 0);
        }
    }
    for (arr_chk = 0; arr_chk < z_size - 3; arr_chk++) {
        if (z[arr_chk] == z[arr_chk + 2] && z[arr_chk + 1] == z[arr_chk + 3] &&
            chk_func(1, z, arr_chk, arr_chk + 4) == 0) {
            if (y[arr_chk] == y[arr_chk + 1] && y[arr_chk + 2] == y[arr_chk + 3] &&
                chk_func(1, y, arr_chk, arr_chk + 4) == 0) {
                if (chk_func(2, x, arr_chk, arr_chk + 4) == 0) {
                    change(x, y, z, 2, arr_chk + 2, arr_chk + 4);
                }
            }
        }
    }
    cout << "------\nPATH : " << endl;
    cout << "X--Y--Z--Input" << endl;
    for (print_elem = 0; print_elem < z_size; print_elem++) {
        if (y[print_elem] != -1) {
            cout << x[print_elem] << "--" << y[print_elem] << "--" << c[print_elem] << "--" << z[print_elem] << endl;
        }
    }
    int symmetries_chk = 0;
    int sum_path = 0;
    if (repeat_chk(0, x, 0, x_size) == repeat_chk(0, x, 1, x_size)) {
        for (arr_chk = 0; arr_chk < int(y_size / 2); arr_chk += 1) {
            if (z[arr_chk] != z[arr_chk + int(y_size / 2)] - int(y_size / 4) && y[arr_chk] != -1) {
                symmetries_chk += 1;
            }
        }
    } else {
        symmetries_chk = -1;
    }
    if (symmetries_chk == 0) {
        for (del_elem = int(y_size / 2); del_elem < y_size; del_elem++) {
            change(x, y, z, 1, del_elem, 0);
        }
        for (arr_chk = 0; arr_chk < int(y_size / 2) - 4; arr_chk++) {
            if (chk_func(1, z, arr_chk, arr_chk + 4) == 0 && z[arr_chk] == z[arr_chk + 2] &&
                z[arr_chk + 1] == z[arr_chk + 3]) {
                change(x, y, z, 2, arr_chk + 2, arr_chk + 4);
            }
        }
        for (sum_z = 0; sum_z < z_size; sum_z++) {
            if (z[sum_z] != -1 && repeat_chk(0, z, 0, z_size) + repeat_chk(0, z, 1, z_size) > 1) {
                sum_path += 1;
            }
        }
        for (sum_y = 0; sum_y < y_size / 2; sum_y++) {
            if (repeat_chk(0, y, y[sum_y], y_size) == 2 && y[sum_y] != -1 && repeat_chk(0,y,-1,y_size) != y_size - 2) {
                sum_y += 1;
                sum_path += 1;
            }
        }
    } else {
        for (arr_chk = 0; arr_chk < z_size - 4; arr_chk++) {
            if (chk_func(1, z, arr_chk + 2, arr_chk + 4) == 0 && z[arr_chk] == z[arr_chk + 2] &&
                z[arr_chk + 1] == z[arr_chk + 3]) {
                change(x, y, z, 2, arr_chk + 2, arr_chk + 4);
            }
        }
        sum_x_0 = repeat_chk(0, x, 1, (x_size));
        sum_x_1 = repeat_chk(0, x, 0, (x_size));
        if (sum_x_0 >= 2 && sum_x_1 >= 2) {
            sum_path += 2;
        } else if (sum_x_0 < 2 || sum_x_1 < 2) {
            sum_path += 1;
        } else {
            cout << "This route is not exist." << endl;
        }
        for (arr_chk = 0; arr_chk < y_size; arr_chk += 2) {
            if (chk_func(2, y, arr_chk, arr_chk + 2) == 0 && chk_func(1, y, arr_chk, arr_chk + 2) == 0) {
                for (arr_chk_sub = arr_chk + 2; arr_chk_sub < z_size; arr_chk_sub += 2) {
                    if (z[arr_chk] == z[arr_chk_sub] && z[arr_chk + 1] == z[arr_chk_sub + 1] &&
                        chk_func(1, z, arr_chk_sub, arr_chk_sub) == 0) {
                        change(x, y, z, 2, arr_chk_sub, arr_chk_sub + 2);
                        sum_path += 1;
                    }
                }
            }
        }
        for (sum_z = 0; sum_z < z_size; sum_z++) {
            if (z[sum_z] != -1) {
                sum_path += 1;
            }
        }
        for (sum_y = 0; sum_y < y_size; sum_y++) {
            if (repeat_chk(0, y, y[sum_y], y_size) == 2 && y[sum_y] != -1) {
                sum_y += 1;
                sum_path += 1;
            }
        }
    }
    cout << "------\nLEAF NUM : " << repeat_chk(0, z, 1, z_size) + repeat_chk(0, z, 0, z_size) << endl;
    cout << "SUM PATH : " << sum_path << endl;
    cout << "SUM NODE : " << int(sum_path / 2) << endl;
    cout << "------" << endl;
}

int zdd(int meta[8]) {
    int *META_CHK = meta;
    int arr_chk1[] = {0, 0, 0, 0, 0, 0, 0, 0};
    int arr_chk2[] = {1, 1, 1, 1, 1, 1, 1, 1};
    //int x[8] = {0,0,0,0,1,1,1,1};
    int y[8] = {0, 0, 1, 1, 2, 2, 3, 3};
    //int z[8] = {0,1,2,3,4,5,6,7};
    if (meta == arr_chk1 || meta == arr_chk2) {
        //cout << "The route doesn't exist" << endl;
    } else {
        for (int i = 0; i < 8; i++) {
            if (i % 2 == 0 && meta[i + 1] == 0) {
                y[i + 1] = -1;
                meta[i + 1] = -1;
            }
        }

        for (int j = 0; j < 8; j++) {
            if (j % 4 == 0 && j == 0) {
                if (meta[j] == 0 && meta[j + 1] == -1 && meta[j + 2] == 0 && meta[j + 3] == -1) {
                    meta[j + 2] = -1;
                    y[j + 2] = -1;
                }
            } else if (j % 4 == 0 && j == 4) {
                if (meta[j] == 0 && meta[j + 1] == -1 && meta[j + 2] == 0 && meta[j + 3] == -1) {
                    meta[j] = -1;
                    meta[j + 2] = -1;
                    y[j] = -1;
                    y[j + 2] = -1;
                } else {
                    break;
                }
            }
        }

        for (int k = 0; k < 8; k++) {
            if (k % 4 == 2) {
                if (META_CHK[k] == 0 && META_CHK[k + 1] == 0) {
                    meta[k] = -1;
                    y[k] = -1;
                }
            }
        }
    }
    for (int i = 0; i < 8; i++) {
        cout << meta[i] << ends;
    }
    cout << endl;
    return 0;
}
