# iPWS Tool
Based iPWS Offical Tools

# Usgae
## -> script  run
1.```python/in/path/python -m pip install -r requirement.txt```
 or
 ```python -m pip install -r requirement.txt```
 
2.```python/in/path/python iPWS_Tool_Evaluation.py```
 or
 ```python iPWS_Tool_Evaluation.py```

## -> package  .py
Try to exit the conda virtual environment before doing the library installation and packaging. pandas' INTEL-specific linear library MKL will be installed in the conda virtual environment by default, which will increase the size of the package.

0.(select)```conda deactivate```

1.```python/in/path/python -m pip install -r requirement.txt```
or
 ```python -m pip install -r requirement.txt```
 
2.```python/in/path/python -m pip install pyinstaller```
or
 ```python -m pip install pyinstaller```
 
 3.```pyinstaller -F iPWS_Tool_Evaluation.py```
 
 4.Insert ```import sys ; sys.setrecursionlimit(sys.getrecursionlimit() * 5)``` in the second line of ```iPWS_Tool.spec``` file
 
 5.```pyinstaller iPWS_Tool_Evaluation.spec```

 6.move the packed iPWS_Tool_Evaluation from the dist folder to another path, then delete ```dist, build, iPWS_Tool_Evaluation.spec```

