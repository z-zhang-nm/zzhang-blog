---
title: "Ubuntu更新显卡驱动后开机黑屏"
date: 2020-09-01T16:55:55+08:00
categories:
- 问题解决
tags:
- 拦路虎
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---

<!--more-->
# 不要使用系统推荐的驱动
　　安装系统推荐的显卡驱动后，开机后进不去图形界面，也进不去命令行模式，后重启按`Esc`进入选择菜单，选择`Ubuntu`行后按`e`进入编辑模式，看到最后两行发现安装驱动后默认给我升级了系统内核，本来是45，升级到了112，导致不能进入系统，将112修改为45后成功进入系统。

# 手动安装显卡驱动
1. 到英伟达官网下载显卡对应的的驱动(.run文件)
2. 屏蔽nouveau驱动：Ubuntu系统集成的显卡驱动程序是nouveau，它是第三方为NVIDIA开发的开源驱动，我们需要先将其屏蔽才能安装NVIDIA官方驱动，所以我们要先把驱动加到黑名单blacklist.conf里
   1. 修改文件属性：`sudo chmod 666 /etc/modprobe.d/blacklist.conf`
   2. 在最后一行加入下面几行语句： `blacklist vga16fb blacklist nouveau blacklist rivafb blacklist rivatv blacklist nvidiafb`
   3. 更新文件：`sudo update-initramfs -u`
3. 重启系统，进入命令行模式`Ctrl+Alt+F1`
4. 关闭图形界面：`sudo service lightdm stop`
5. 卸载可能残留的Nvidia驱动：`sudo apt-get remove --purge nvidia*`
6. 进入下载的驱动run文件目录并赋予其可执行权限：`sudo chmod a+x NVIDIA-Linux-x86_64-xxx.run`
7. 进行安装：`sudo ./NVIDIA-Linux-x86_64-xxx.run -no-x-check -no-nouveau-check -no-opengl-files`
8. 在安装过程中会出现：
   1. he distribution-provided pre-install script failed! Are you sure you want to continue? 选择**Yes**
   2. Would you like to register the kernel module souces with DKMS? This will allow DKMS to automatically build a new module, if you install a different kernel later? 选择**No**
   3. 32 bit? 选择**No**
   4. Would you like to run the nvidia-xconfigutility to automatically update your x configuration so that the NVIDIA x driver will be used when you restart x? Any pre-existing x confile will be backed up. 选择**Yes**
9. 启动图形界面：`sudo service lightdm start`
10. 验证安装：`nvidia-smi`，显示显卡信息表示安装成功

# 切换系统内核
1. 查看系统可用的 Linux 内核：`grep menuentry /boot/grub/grub.cfg`
2. 修改Grub，设置内核启动版本：`sudo gedit /etc/default/grub`，将`GRUB_DEFAULT`设置为想要的内核版本：`GRUB_DEFAULT="Linux 4.15.0-99-generic"`
3. 更新Grub：`sudo update grub`，根据提示修改`GRUB_DEFAULT`为正确的名字
4. 重启并查看系统内核：`uname -r`

# 安装Linux内核
1. 查看可安装的内核：`sudo apt-cache search linux-image | grep generic`
2. 安装新内核：`sudo apt-get install linux-image-4.4.0-108-generic`

# 卸载Linux内核
`sudo apt-get remove(或用purge) linux-image-4.4.0-105-generic`