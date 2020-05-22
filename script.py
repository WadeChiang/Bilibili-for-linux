# coding=utf-8
import urllib3
import certifi
import json
import time
import sys

http = urllib3.PoolManager(cert_reqs='CERT_REQUIRED', ca_certs=certifi.where())


# 返回文本格式(每行): mid`uname
def get_subscribe_list(mid):  # 自动获取关注列表
    output_str = ''
    # 模拟翻页
    for page in range(1, 6):
        url = "https://api.bilibili.com/x/relation/followings?vmid={}&pn={}&ps=50&order=desc&jsonp=jsonp".format(mid,
                                                                                                                 page)
        # print(url)
        r = http.request('GET', url)
        subscribe_list = json.loads(r.data.decode("utf-8"))['data']['list']
        for i in subscribe_list:
            # print(str(i['mid']) + ' ' + str(i['uname']))
            output_str = output_str + str(i['mid']) + '`' + str(i['uname']) + '\n'
        time.sleep(0.5)
    print(output_str, end='')


# 返回文本格式: fans_num
def get_up_fans(mid):  # 获取某一个up的信息（粉丝数、获赞数、播放数）
    # 获取粉丝数
    url = "https://api.bilibili.com/x/relation/stat?vmid={}&jsonp=jsonp".format(mid)
    r = http.request('GET', url)
    fans_num = json.loads(r.data.decode("utf-8"))['data']['follower']
    output_str = str(fans_num) + '\n'
    print(output_str, end='')


# 获取up主的信息，用于展示
def get_up_info(mid):
    url = "https://api.bilibili.com/x/relation/stat?vmid={}&jsonp=jsonp".format(mid)
    r = http.request('GET', url)
    fans_num = json.loads(r.data.decode("utf-8"))['data']['follower']
    url = "https://api.bilibili.com/x/space/upstat?mid={}&jsonp=jsonp".format(mid)
    r = http.request('GET', url)
    data = json.loads(r.data.decode("utf-8"))['data']
    likes = data['likes']
    view = data['archive']['view']
    url = "https://api.bilibili.com/x/space/acc/info?mid={}&jsonp=jsonp".format(mid)
    r = http.request('GET', url)
    data = json.loads(r.data.decode("utf-8"))['data']
    name = data['name']
    sign = data['sign']
    face_address = data['face']
    print("UP名称:{}\n个性签名:{}\n\n粉丝数:{} 播放量:{} 点赞数:{}`{}".format(name,sign,fans_num,view,likes,face_address))


def get_vedio_info(aid):
    url = "https://api.bilibili.com/x/web-interface/archive/desc?aid={}".format(aid)
    r = http.request('GET', url)
    intro = json.loads(r.data.decode("utf-8"))['data']
    print(intro)


# 返回文本格式(每行): aid`title`creat_time`length`view`pic_address
def get_vedio_list(mid):
    output_str = ''
    page = 1
    vedio_num_per_page = 100  # 每页的视频数
    while True:  # 模拟翻页
        url = "https://api.bilibili.com/x/space/arc/search?mid={}&ps={}&tid=0&pn={}&keyword=&order=pubdate&jsonp=jsonp".format(
            mid, vedio_num_per_page, page)
        r = http.request('GET', url)
        data = json.loads(r.data.decode("utf-8"))['data']
        vlist = data['list']['vlist']
        for v in vlist:
            aid = v['aid']
            title = v['title']
            creat_time = v['created']
            length = v['length']
            view = v['play']
            pic_address = v['pic']

            v_str = str(aid) + '`' + title + '`' + time.strftime("%Y-%m-%d %H:%M", time.localtime(creat_time)) + '`' + length + '`' + str(
                view) + '`' + pic_address + '\n'
            # print(v_str)
            output_str += v_str
        # 判断是否获取所有视频信息
        if data['page']['count'] <= page * vedio_num_per_page:
            break
        page += 1
        time.sleep(1)
    print(output_str, end='')


def main():
    if sys.argv[1] == "get_subscribe_list":  # 获取关注列表
        get_subscribe_list(sys.argv[2])
    elif sys.argv[1] == "get_up_fans":  # 获取某一个up的粉丝数
        get_up_fans(sys.argv[2])
    elif sys.argv[1] == "get_vedio_list":  # 获取一个up的视频列表和视频信息
        get_vedio_list(sys.argv[2])
    elif sys.argv[1] == "get_up_info": # 获取up主的信息，用于展示
        get_up_info(sys.argv[2])
    elif sys.argv[1] == "get_vedio_info": # 获取视频的信息，用于展示
        get_vedio_info(sys.argv[2])


if __name__ == '__main__':
    main()
