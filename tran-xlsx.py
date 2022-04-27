import csv
import os

import pandas as pd
import xlwt

#定义文件路径与表名称
#EXCEL_PATH = "/Users/xxxxx/Desktop/xxxxxx.csv"
EXCEL_PATH = input("Input CSV FILE PATH or Put CSV FILE in THIS WINDOWS.\n>>").strip("'")
EXCEL_XLS_NAME = EXCEL_PATH.replace(EXCEL_PATH.split(".")[-1],"")+"xls"
EXCEL_XLSX_NAME = EXCEL_PATH.replace(EXCEL_PATH.split(".")[-1],"")+"xlsx"

#文件类型转换 CSV->XLS->XLSX
if os.path.splitext(EXCEL_PATH)[1] in {".csv",".CSV"}:
    #encoding：utf-8,gbk,shift-jis
    with open(EXCEL_PATH, 'r', encoding='shift-jis',errors="ignore") as CSV_DATA:
        EXCEL_WRB = xlwt.Workbook()
        EXCEL_SHT = EXCEL_WRB.add_sheet('data')
        SHEET_ROW = 0
        for SHEET_LINE in csv.reader(CSV_DATA):
            SHEET_CELL = 0
            for CELL in SHEET_LINE:
                EXCEL_SHT.write(SHEET_ROW, SHEET_CELL, CELL)
                SHEET_CELL += 1
            SHEET_ROW += 1
        EXCEL_WRB.save(EXCEL_XLS_NAME)
    ######## 转换 XLS->XLSX ###########
    #只转换XLS文件的可以注释掉或者删除这部分
    XLS_DATA = pd.DataFrame(pd.read_excel(EXCEL_XLS_NAME,engine="xlrd"))
    XLS_DATA.to_excel(EXCEL_XLSX_NAME, index=False)
    EXCEL_PATH = EXCEL_PATH.replace(EXCEL_PATH.split(".")[-1],"xlsx")
    os.remove(EXCEL_XLS_NAME)
    ###################################
else:
    print("FILE IS NOT A CSV FILE.\n")
