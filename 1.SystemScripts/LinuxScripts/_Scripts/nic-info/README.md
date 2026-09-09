# nic-info.sh 使用说明

`nic-info.sh` 是一个用于快速查看 Linux 网络接口信息的 Shell 脚本。

脚本支持按接口类型、接口状态、IP 版本和显示字段进行筛选，适合在 Ubuntu Server 等环境中作为日常网络排障和接口管理工具使用。

---

## 功能

支持显示以下信息：

- NIC 名称
- 接口状态
- MAC 地址
- NIC Alias
- IPv4 地址
- IPv6 地址

支持：

- 只显示设备型 NIC
- 显示全部 NIC
- 只显示 UP 状态 NIC
- 指定一个或多个 NIC
- 只显示 IPv4
- 只显示 IPv6
- 同时显示 IPv4 和 IPv6
- 自定义显示字段
- 隐藏表头

---

## 兼容环境

脚本使用 POSIX Shell 语法，Shebang：

```sh
#!/bin/sh
```

可用于：

- `sh`
- `dash`
- `bash`
- `zsh`

Ubuntu Server 中 `/bin/sh` 默认通常指向 `dash`。

---

## 推荐路径

脚本：

```text
/root/_ScriptsAndPrograms/_SYSTEM_USED_SCRIPTS/nic-info.sh
```

赋予执行权限：

```sh
chmod 700 /root/_ScriptsAndPrograms/_SYSTEM_USED_SCRIPTS/nic-info.sh
```

---

## 推荐创建短命令

创建软链接：

```sh
ln -s /root/_ScriptsAndPrograms/_SYSTEM_USED_SCRIPTS/nic-info.sh /usr/local/sbin/nics
```

之后可以直接执行：

```sh
nics
```

---

# 默认行为

直接执行：

```sh
nics
```

默认：

- 只显示设备型 NIC
- 不显示 `lo`
- 不显示 Docker Bridge
- 不显示 `veth`
- 同时显示 IPv4 和 IPv6
- 显示以下字段：

```text
NIC | STATE | MAC | ALIAS | IPv4 | IPv6
```

示例：

```text
NIC                  STATE    MAC                ALIAS                      IPv4                     IPv6
-------------------- -------- ------------------ -------------------------- ------------------------ --------------------------------
ens160               up       00:0c:29:fa:bf:66  TLAN_10_3                  10.3.193.1/16            fe80::20c:29ff:fefa:bf66/64
ens192               down     00:0c:29:fa:bf:70  172_16_16_NET              -                        -
ens224               down     00:0c:29:fa:bf:84  TLAN_10_3_Second           -                        -
ens36                down     00:0c:29:fa:bf:7a  SophosProduct              -                        -
```

---

# 参数

## 接口选择

### `-p`, `--physical`

只显示设备型 NIC。

这是默认模式。

```sh
nics --physical
```

或：

```sh
nics -p
```

脚本通过以下路径判断接口是否属于设备型 NIC：

```text
/sys/class/net/<NIC>/device
```

如果该路径存在，则认为该接口具有底层设备。

例如在 VMware 虚拟机中：

```text
ens160
ens192
ens224
ens36
```

虽然它们底层是虚拟硬件，但从 Guest OS 角度仍然属于设备型 NIC，因此会被显示。

通常以下接口不会显示：

```text
lo
docker0
br-xxxxxxxxxxxx
vethxxxxxxx
```

---

### `-a`, `--all`

显示系统中的全部网络接口。

```sh
nics --all
```

或：

```sh
nics -a
```

例如可能包含：

```text
ens160
ens192
docker0
br-4fcefedd5dba
veth0d095e6
lo
```

---

### `-i`, `--interface`

只显示指定接口。

```sh
nics -i ens160
```

或：

```sh
nics --interface ens160
```

也支持：

```sh
nics --interface=ens160
```

可以指定多个：

```sh
nics -i ens160 -i ens192
```

---

### `-u`, `--up-only`

只显示当前状态为 `up` 的接口。

```sh
nics --up-only
```

可以与其他参数组合：

```sh
nics --all --up-only
```

---

# IP 显示模式

## `-4`, `--ipv4-only`

只显示 IPv4。

```sh
nics -4
```

等价于：

```sh
nics --ipv4-only
```

默认字段：

```text
NIC | STATE | MAC | ALIAS | IPv4
```

---

## `-6`, `--ipv6-only`

只显示 IPv6。

```sh
nics -6
```

等价于：

```sh
nics --ipv6-only
```

默认字段：

```text
NIC | STATE | MAC | ALIAS | IPv6
```

---

## `-46`, `--dual-stack`

同时显示 IPv4 和 IPv6。

```sh
nics -46
```

等价于：

```sh
nics --dual-stack
```

这是默认模式。

默认字段：

```text
NIC | STATE | MAC | ALIAS | IPv4 | IPv6
```

---

# 自定义字段

## `-f`, `--fields`

可以自定义需要显示的列。

支持的字段：

| 字段 | 含义 |
|---|---|
| `nic` | NIC 名称 |
| `state` | 接口状态 |
| `mac` | MAC 地址 |
| `alias` | NIC Alias |
| `ipv4` | IPv4 地址 |
| `ipv6` | IPv6 地址 |

格式：

```sh
nics --fields FIELD1,FIELD2,FIELD3
```

例如：

```sh
nics --fields nic,alias,ipv4
```

输出：

```text
NIC                  ALIAS                      IPv4
-------------------- -------------------------- ------------------------
ens160               TLAN_10_3                  10.3.193.1/16
ens192               172_16_16_NET              -
ens224               TLAN_10_3_Second           -
ens36                SophosProduct              -
```

简写：

```sh
nics -f nic,alias,ipv4
```

---

## 自定义字段顺序

字段顺序可以自由调整。

例如：

```sh
nics -f alias,nic,state,ipv4
```

输出列顺序也会按照指定顺序排列：

```text
ALIAS | NIC | STATE | IPv4
```

---

# 隐藏表头

使用：

```sh
nics --no-header
```

例如：

```sh
nics --no-header -f nic,ipv4
```

适合将输出继续传给其他命令处理。

---

# 常见用法

## 查看设备型 NIC

```sh
nics
```

---

## 查看全部 NIC

```sh
nics -a
```

---

## 只查看 IPv4

```sh
nics -4
```

---

## 只查看 IPv6

```sh
nics -6
```

---

## 查看 IPv4 和 IPv6

```sh
nics -46
```

---

## 只看 UP 状态接口

```sh
nics -u
```

---

## 查看所有 UP 状态接口

```sh
nics -a -u
```

---

## 查看指定 NIC

```sh
nics -i ens160
```

---

## 查看多个指定 NIC

```sh
nics -i ens160 -i ens192
```

---

## 只查看 NIC、Alias 和 IPv4

```sh
nics -f nic,alias,ipv4
```

---

## 只查看 NIC、MAC 和 Alias

```sh
nics -f nic,mac,alias
```

---

## 查看全部接口，但只显示 NIC、状态、Alias 和 IPv4

```sh
nics -a -f nic,state,alias,ipv4
```

---

## 查看全部 UP 状态接口，只显示 IPv4

```sh
nics -a -u -4
```

---

## 查看指定接口的双栈地址

```sh
nics -i ens160 -f nic,alias,ipv4,ipv6
```

---

# Alias

NIC Alias 可以通过：

```sh
ip link set dev ens160 alias "TLAN_10_3"
```

设置。

查看：

```sh
ip link show dev ens160
```

Alias 实际存储于：

```text
/sys/class/net/ens160/ifalias
```

`nic-info.sh` 会直接读取该字段，因此可以同时显示：

```text
NIC
STATE
MAC
ALIAS
IPv4
IPv6
```

而不需要分别执行：

```sh
ip link show
```

和：

```sh
ip addr show
```

---

# Physical 模式说明

这里的 `physical` 更准确地说是：

```text
Device-backed NIC
```

判断条件：

```text
/sys/class/net/<NIC>/device
```

存在。

因此它并不意味着接口一定来自物理 PCIe 网卡。

例如：

- VMware VM 的 VMXNET3 / E1000 NIC
- Proxmox VM 的 VirtIO NIC
- 其他 Hypervisor 提供给 Guest OS 的虚拟硬件 NIC

对于 Guest OS 来说，它们仍然属于设备型 NIC，因此会被 `--physical` 显示。

而以下纯软件接口通常不会被显示：

```text
lo
docker0
br-*
veth*
```

如果需要查看这些接口，请使用：

```sh
nics --all
```

---

# 参数速查

| 参数 | 简写 | 说明 |
|---|---|---|
| `--physical` | `-p` | 只显示设备型 NIC，默认 |
| `--all` | `-a` | 显示全部 NIC |
| `--interface NAME` | `-i NAME` | 只显示指定 NIC |
| `--up-only` | `-u` | 只显示 UP 状态 NIC |
| `--ipv4-only` | `-4` | 只显示 IPv4 |
| `--ipv6-only` | `-6` | 只显示 IPv6 |
| `--dual-stack` | `-46` | 显示 IPv4 + IPv6，默认 |
| `--fields LIST` | `-f LIST` | 自定义显示字段 |
| `--no-header` | - | 不显示表头 |
| `--help` | `-h` | 显示帮助 |

---

# 完整帮助

执行：

```sh
nics --help
```

或：

```sh
nics -h
```

查看脚本内置帮助。
