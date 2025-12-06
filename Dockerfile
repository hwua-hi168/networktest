# 使用 Ubuntu 最新版本作为基础镜像
FROM ubuntu:latest

# 设置环境变量，避免安装时交互
ENV DEBIAN_FRONTEND=noninteractive

# 1. 安装基础网络诊断工具
# iproute2 包含 ip 命令，net-tools 包含 ifconfig, arp 等[citation:4][citation:7]
# dnsutils 包含 nslookup, dig[citation:4]
RUN apt-get update && apt-get install -y \
    iproute2 \
    net-tools \
    iputils-ping \
    iputils-tracepath \
    traceroute \
    tcpdump \
    dnsutils \
    curl \
    wget \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 FRRouting (FRR)
# 添加 FRR 官方仓库并安装[citation:10]
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository ppa:frrouting/frr \
    && apt-get update && apt-get install -y frr frr-pythontools \
    && rm -rf /var/lib/apt/lists/*

# 3. 安装 Trojan-Go
# 下载最新版的 Trojan-Go 二进制文件
WORKDIR /usr/local/bin
RUN LATEST_TAG=$(curl -s https://api.github.com/repos/p4gefau1t/trojan-go/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO "https://github.com/p4gefau1t/trojan-go/releases/download/${LATEST_TAG}/trojan-go-linux-amd64.zip" \
    && apt-get update && apt-get install -y unzip \
    && unzip trojan-go-linux-amd64.zip \
    && rm trojan-go-linux-amd64.zip \
    && chmod +x trojan-go

# 4. 创建配置文件目录和启动脚本
WORKDIR /root
COPY frr.conf /etc/frr/frr.conf
COPY trojan-go-config.json /etc/trojan-go/config.json
COPY entrypoint.sh /entrypoint.sh

# 5. 设置内核转发参数（为FRR准备）
RUN echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf \
    && echo "net.ipv4.conf.all.forwarding=1" >> /etc/sysctl.conf[citation:10]

# 6. 设置启动脚本为可执行并声明启动命令
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
