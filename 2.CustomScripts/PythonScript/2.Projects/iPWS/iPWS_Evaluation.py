from math import floor
from os import path

from numpy import exp
from pandas import DataFrame, concat
from pandas import read_csv as prc
import statsmodels.api as sm
import statsmodels.formula.api as smf
from InputClean.InputClean import ci

# Define dfOD, df_orig = original_data CSV
# Define dfAD, df_anon = Anonymous_data CSV

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
    da['COVID'] = 1
    do['COVID'] = 1
    
    du.columns = ['AGE', 'GENDER', 'RACE', 'INCOME', 'EDUCATION', 'VETERAN',
                  'NOH', 'HTN', 'DM', 'IHD', 'CKD', 'COPD', 'CA', 'COVID']
    
    da = concat([da, du])
    do = concat([do, du])
    
    da.to_csv(f'{path.split(adp)[0]}/test1.csv', index = None, header = None)
    do.to_csv(f'{path.split(odp)[0]}/test2.csv', index = None, header = None)
    input()
    
    da = odds(da)['OR']
    do = odds(do)['OR']
    
    score_c = max(1- ((da - do).abs().max()) / 20, 0)
    score_d = max(1- ((da - do).abs().mean()) / 20, 0)
    
    return score_c, score_d

if __name__ == '__main__':
    adp = ci('ad >> ')
    odp = ci('od >> ')
    dup = ci('du >> ')
    
    ad = prc(adp, header=None)
    od = prc(odp, header=None)
    du = prc(dup)
    
    od[0] = od[0].apply(lambda x : floor(x / 10) * 10)
    ad[0] = ad[0].apply(lambda x : floor(x / 10) * 10)
    
    a, b = agDiff(od, ad), corrDiff(od, ad)
    print(f'ScoreA  : {a}')
    print(f'ScoreB  : {b}')
    c, d = oddsDiff(od, ad)
    print(f'ScoreC  : {c}')
    print(f'ScoreD  : {d}')
    print(f'Average : {(a + b + c + d) / 4}')