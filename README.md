Redis+keepalived实现的高可用
================

通过keepalived来的ip 漂移来实现的redis 服务的高可用


----
### 介绍

基本原理是通过keepalived的vrrp_scrips,定期用redis-cli 去取redis的info返回,如果返回时间超过keepalived vrrp_scripts的超时时间,keepalived会进入faild 状态,从而触发keepalived集群开始进行vip漂移.

###如何使用
#### 安装keepalived需要的脚本

把相应的.sh脚本放下载回来放到/opt/scripts/下面,供keepalived调用
#### keepalived的配置文件

直接把keepalvied的配置文件放到keepalived的读取位置(默认/etc/keepalive/keepalived.conf),keepalived配置文件的主从配置唯一的区别在于vrrp_instance redis165 里面的priority 不一样.其它都是一样的.

###限制说明
####不适用于对高可用特别敏感的应用

  keepalived在检测的redis失败并成功进行IP漂移的时候,redis的服务会有一定的中断时间,这个时间是健康检测周期+keepalived的漂移时间(1右)所限制的,总体来说可以控制到10左右.
  
####不能连续发生多次切换
   这个限制的根本原因是redis的主从同步引起的.
   keepalived在切换切换时会触发一个脚本从新设置redis的主从角色，redis在2.8以前的版本.主从同步都是全量的,这个根据数据量主从同步时间也是不一定的.redis主从同步主要过程为从触发主进行bgsave,生成rdb文件,然后此rdb文件传输到从服务器上.redis从把此rdb文件load进内存.这个时间的长短要看网络和磁盘IO.所以当切换发生在主从没有完全同步好的时候,就会生数据丢失问题.
   
   
####存在主从设置失败的问题
 
 这个限制的根本原因是因为redis在load数据进redis的时候,针对redis服务器任何操作都是无法进行的.
 设置主从失败的问题,一般只发生在一台数据量比较大redis服务器的被重启,当redis服务刚起动的时候,会通过aof 或是rdb 加载数据,这个时候keepalived会触发重新设置redis服务器为从就会失败,遇到这种情况,只要等redis数据加载完毕后reload一把keepalived服务就可.
 
