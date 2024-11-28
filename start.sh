#!/bin/bash

# 获取 Pod 名称
POD_NAME=$POD_NAME  # 该环境变量在容器中通过 Downward API 获取

# 通过 Pod 名称的后缀（例如 "one-api-0"）来决定 NODE_TYPE
if [[ "$POD_NAME" == "maas-one-api-0" ]]; then
  export NODE_TYPE="master"  # 第一个副本设置为 master
else
  export NODE_TYPE="slave"   # 其他副本设置为 slave
fi

# 打印 NODE_TYPE 调试
echo "NODE_TYPE is set to $NODE_TYPE"
exec /one-api --log-dir /app/logs
