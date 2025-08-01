# Go2_Mid360_Livox
记录给宇树机器狗安装和调试Mid360

## 安装mid360
### 线缆的问题
商家可能会随机发送三头线，xt30线等的线缆。  
和狗连线的方式有两种：  
- 线缆一：雷达的12口航空接头------狗的8口航空接头（找淘宝商家定做）
- 线缆二：雷达的12口航空接头------三头线，三头线的功能线不用，剩下网线和电源线
	+ 连狗的话，网线连拓展坞上，电源线用xt30连狗上
	+ 连电脑的话，网线正常连，电源线焊接/用绝缘胶带把铜丝接上带二头插座的线，注意看说明书的电压范围
### 螺丝和保护壳的问题
自行找合适的

## 配置mid360
### 配置IP
雷达出场自带1网段的IP,如果想要为了后续机器狗的协作（如SLAM接口）调整网段和IP的话，就需要去修改雷达的IP。  
雷达的IP貌似只能[在Livox Viewer上修改](https://blog.csdn.net/bscren/article/details/147873079?ops_request_misc=%257B%2522request%255Fid%2522%253A%25227bcccdcd38e0991e1944b5740b44b733%2522%252C%2522scm%2522%253A%252220140713.130102334..%2522%257D&request_id=7bcccdcd38e0991e1944b5740b44b733&biz_id=0&utm_medium=distribute.pc_search_result.none-task-blog-2~all~sobaiduend~default-1-147873079-null-null.142^v102^pc_search_result_base7&utm_term=mid360%20IP&spm=1018.2226.3001.4187)，Livox Viewer不支持arm架构，所以不能在拓展坞上面装，如果要修改IP的话还是逃不掉先用线缆二把雷达连个人电脑的命运。  (貌似虚拟机也不行？)  
注意一开始先把电脑的网口改成1网段才能和初始雷达通信。  


### 配置config文件
- 修改IP后，下载SDK和driver,修改配置文件。  
- 参考链接：  
	[览沃MID-360装配在ubuntu22.04+ros2快速指南](https://blog.csdn.net/bitswh/article/details/148477007)。  
	[Livox-Mid-360激光雷达配置](https://blog.csdn.net/m0_49384824/article/details/142483862)

注意参考链接1里面的./build.sh humble，要在～/ws_livox/src/livox_ros_driver2路径下运行  
- 常见报错  
运行ros2 launch livox_ros_driver2 rviz_MID360_launch.py的时候
	* 报错信息出现网卡具体名称，CycloneDDS等字样  
	看看是不是./bashrc文件里source了source ~/unitree_ros2/setup.sh，用“#”注释掉试试（也就是说，运行雷达的那个终端不要source宇树的环境，想要source宇树的环境执行机器狗操作的时候要另开终端source,不要在全局bashrc里面就把宇树的环境变量给source了）
	* 进去rviz2后只有网格没有点云  
	终端报错信息显示：
	```
	ERROR：Could not load library dlopen error: liblivox_lidar_sdk_shared.so: cannot open shared object file: No such file or directory
	```
	你的系统找不到 Livox SDK 的动态库 liblivox_lidar_sdk_shared.so，这通常是因为 环境变量 LD_LIBRARY_PATH 没有包含 SDK 安装目录。  
	而liblivox_lidar_sdk_shared.so 在 `/usr/local/lib/liblivox_lidar_sdk_shared.so`下面   
	在终端中先输入`export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH`  
	然后再运行`ros2 launch livox_ros_driver2 rviz_MID360_launch.py`  

- MID360_config.json文件  
	![复古风格](../图片/截图/截图 2025-08-01 11-34-16.png)
	里面的IP地址，我设置的是雷达IP：192.168.123.158，个人电脑网口IP：192.168.123.50  
	
	修改config文件后记得重新编译`./build.sh humble`
	
	config里面的extrinsic_parameter用来对雷达的坐标进行变换。  
	extrinsic_parameter：外部参数，为雷达坐标系相对于某个父坐标系（如机器人基座 base_link）的外参变换，即 T_(base_link)_(livox_frame) ，用于将雷达坐标系下的点云转到该父坐标系下。特别注意：改变该值会改变 lidar 和 imu 的外参，需要重新对imu和lidar进行标定，所以通常不建议修改该值！！！（？）“roll”“picth”“yaw”的数据类型为float，单位为度。"x" "y" "z" 的数据类型为 int，不能有小数点，单位为 mm。
	在这个config文件里修改可以直接修改坐标变化。  
	
	当然你也可以用
	```
	ros2 run tf2_ros static_transform_publisher \ 0.2 0 0.1 0 0 0 \ utlidar_lidar livox_frame
	```
	来进行静态坐标变换。 至于如何得到精确的变换矩阵，则需要标定。
	
 - 标定  
 	对于mid360坐标系和狗中心坐标系之间的变换关系，虽然宇树文档有给变换矩阵，但是最好需要重新标定测量一下。  
 	
 	狗雷达坐标应该是精确的（至少在平移上，旋转不知道）。可以rosbag两个雷达的点云，然后用ICP配准得到两个坐标系的变换矩阵。  
 	
 	rosbag play 的时候，`ros2 run rviz2 rviz2` 打开rviz,add pointcloud，加好对应的tiopic,修改好fixed frame即可，即可看到录制的点云。  
 	
 - 双线同时连接MID360和狗，同时录制两个雷达  
 	注意网口IP、坐标系、话题的对应，我的是：  
 	
 	狗雷达的topic是 /utlidar/cloud，fixed_frame是utlidar_lidar，电脑网口名称是enp57s0，电脑网口IP是192.168.123.99，雷达IP是192.168.123.18   
 	
	mid360的topic是/livox/lidar，fixed_frame是livox_frame，电脑网口名称是enx00e04c681b82，电脑网口IP是192.168.123.50,雷达IP是192.168.123.158
	
	同时连接两个网口，要注意各自流量的转发所走的网口
	
	由于它们在同一个子网（192.168.123.0/24），默认路由表不能区分这两台设备应该从哪个接口走，这就需要用到策略路由（Policy Routing），也就是根据源地址或目标地址来选择路由表。
	
	策略路由配置脚本setup_policy_routing.sh在仓库中，注意修改自己的IP

	可以用 `ping -I 192.168.123.50 192.168.123.158` 验证  
	
	同时可以分别打开rviz，各自调好坐标话题后，可以看到各自的点云，就可以rosbag开始录制了。
	

	


## 其他常见报错/遇到过的报错
### 清理根目录分区
根目录分区“/”要及时清理，否则容易导致进不去ubuntu系统图形化界面

1. 查看存储占用情况  
```
df -h
```

2. 安全的清理方法：

- 把 CUDA 移动到 /home 分区，再用软链接指向它（具体自行ai）
- 清理 APT 缓存和无用包
```
sudo apt clean  
sudo apt autoremove -y
```

- 清理系统日志
```
sudo journalctl --vacuum-time=7d  
sudo du -sh /var/log
```

- 清理 Snap 中的旧版本
```
snap list --all  
#然后删除已禁用的旧版本
```

### 连上狗但是还是没有topic
连上狗source unitree的时候，没有狗的ros2 topic list：  
等一会试试，玄学，或者重启试试


### 连上狗但是rviz没有显示数据
做宇树文档ros2消息接口的时候，rviz没有点云数据，并且报错：
```
[INFO] [rviz]: Message Filter dropping message: frame 'utlidar_lidar' at time ... for reason 'discarding message because the queue is full'
```

显示消息滤波器队列已满：  
也是玄学，等一会试试


