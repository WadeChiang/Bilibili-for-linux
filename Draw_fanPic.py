import matplotlib.pyplot as plt
from matplotlib import font_manager
import numpy as np
import math
import os
import sys

def main():
    mid = sys.argv[1]  #读取up主的uid和名称
    name = ''
    xy_data = []

    with open('up_list','r',encoding = 'utf-8') as up_file:
        uplist = up_file.readlines()
        for each in uplist:
            index = each.find(str(mid))
            mid_len = len(str(mid))
            #print(index,each[index+mid_len])
            if index != -1 and each[index+mid_len] == '`':
                name += each[index+mid_len+1:]   
        #print(name)
    with open('fans_info/{}'.format(mid), 'r') as fan_file:
        while True:
            s = fan_file.readline()
            if not s:  #等价于if line == ""
                break
            #读文件中的数据
            xy_data.append(s)

    x = []
    y = []
    x_num = []
    i = 0 #备用，计算x中的数据个数
    for each in xy_data:
        i = i + 1
        y.append(int(each.partition(',')[0]))
        x.append(each.partition(',')[2][:-1])#数据分片，x为时间，y为粉丝数
        x_num.append(i)

    #print(x,y,x_num)

    my_font = font_manager.FontProperties(fname='scr/handwritefont.ttf') #更改字体

    # fig = plt.figure(num=3,figsize=(10,6),dpi=100)

    y_max = math.ceil(max(y)/100) * 100
    y_min = int(min(y)/100) * 100
    y_ticks = np.linspace(y_min,y_max,11) #设置y轴的上下限

    plt.ylim(y_min,y_max)

    plt.plot(x,y,marker='o')

    plt.xticks(x,rotation=60,size=6.5)
    plt.yticks(y_ticks)

    ax = plt.gca()
    ax.yaxis.get_major_formatter().set_useOffset(False)#让大数字不以科学计数法显示
    ax.spines['right'].set_color('None')  # 将right和top的线条去掉（图上方和右边的边框）
    ax.spines['top'].set_color('None')

    for a,b in zip(x,y):
        plt.text(a, b+0.02*(y_max - y_min), '%.0f' % b, ha='center', va= 'bottom',fontsize=10) #在每个点上方显示数值标签
        
    plt.title('{}涨粉趋势图'.format(name),fontproperties=my_font,fontsize=20)
    plt.xlabel('时间',fontproperties=my_font,fontsize=20)
    plt.ylabel('粉丝数',fontproperties=my_font,fontsize=20)

    plt.show()

if __name__ == '__main__':
    main()
