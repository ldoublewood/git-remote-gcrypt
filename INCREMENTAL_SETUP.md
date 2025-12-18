# Git Remote Gcrypt - 增量模式设置指南

## 概述

这是 git-remote-gcrypt 的增强版本，支持增量推送以减少传输数据量和存储占用。

## 核心特性

### 1. 增量推送模式
- 仅对指定分支启用增量模式
- 其他分支继续使用原有的全量模式
- 基于 commit 范围的智能增量打包

### 2. 新的文件命名规则
- 格式：`[16位序号]-[完整SHA256哈希]`
- manifest 文件：`0000000000000000-[sha256]`
- 增量文件：从 `0000000000000001` 开始递增

### 3. 增强的 manifest 结构
```
version: 1.0
timestamp: 2025-12-18T10:30:00Z
commit_id: abc123...
file_hash: def456...
file_size: 1024
branch: main
```

## 安装和配置

### 1. 安装增量版本
```bash
# 复制增量版本到系统路径
sudo cp git-remote-gcrypt-incremental /usr/local/bin/
sudo chmod +x /usr/local/bin/git-remote-gcrypt-incremental

# 或者创建符号链接
ln -s /path/to/git-remote-gcrypt-incremental ~/.local/bin/git-remote-gcrypt
```

### 2. 配置增量分支
```bash
# 为特定远程仓库配置增量分支
git config remote.origin.gcrypt-incremental-branch "main"

# 或者为多个分支配置（未来支持）
git config remote.origin.gcrypt-incremental-branch "main,develop"
```

### 3. 其他配置选项
```bash
# 启用调试模式
export GCRYPT_DEBUG=1

# 配置 GPG 参数（继承原有配置）
git config gcrypt.participants "KEY1 KEY2"
git config gcrypt.gpg-args "--use-agent"
```

## 使用方法

### 1. 创建增量加密远程仓库
```bash
# 添加远程仓库
git remote add cryptremote gcrypt::rsync://example.com/repo

# 配置增量分支
git config remote.cryptremote.gcrypt-incremental-branch "main"

# 配置参与者
git config remote.cryptremote.gcrypt-participants "YOUR_GPG_KEY"

# 首次推送（全量）
git push cryptremote main
```

### 2. 增量推送
```bash
# 切换到配置的增量分支
git checkout main

# 进行一些提交
git commit -m "Some changes"

# 增量推送（自动检测并使用增量模式）
git push cryptremote main
```

### 3. 增量拉取
```bash
# 增量拉取（自动检测）
git pull cryptremote main
```

## 工作原理

### 1. 推送流程
1. **检测模式**：检查当前分支是否配置为增量模式
2. **获取远程状态**：下载最新的 manifest 文件
3. **计算范围**：确定需要推送的 commit 范围
4. **创建增量包**：仅打包新的 commits 和对象
5. **加密上传**：加密并上传增量包
6. **更新 manifest**：创建新的 manifest 文件

### 2. 拉取流程
1. **检测远程更新**：检查远程 manifest 序号
2. **下载 manifest**：获取最新的 manifest 信息
3. **比较状态**：对比本地和远程 commit
4. **下载增量**：仅下载需要的增量包
5. **应用更新**：解密并应用到本地仓库

### 3. 文件结构示例
```
远程仓库文件结构：
├── 0000000000000000-a1b2c3d4...  # 初始 manifest
├── 0000000000000001-e5f6g7h8...  # 第一次增量包
├── 0000000000000001-i9j0k1l2...  # 第一次增量 manifest
├── 0000000000000002-m3n4o5p6...  # 第二次增量包
└── 0000000000000002-q7r8s9t0...  # 第二次增量 manifest
```

## 性能优势

### 传输数据量对比
- **原版本**：每次推送整个仓库历史
- **增量版本**：仅传输新的 commits

### 存储空间优化
- **原版本**：远程存储完整仓库副本
- **增量版本**：存储增量包，支持历史重建

### 示例场景
```bash
# 仓库大小：100MB，新提交：1MB
# 原版本推送：100MB + 1MB = 101MB 传输
# 增量版本推送：1MB 传输（节省 99%）
```

## 兼容性

### 向后兼容
- 非增量分支继续使用原有格式
- 可以逐步迁移到增量模式
- 支持混合模式操作

### 客户端要求
- 需要使用增量版本的 git-remote-gcrypt
- GPG 配置保持不变
- Git 版本要求：>= 2.0

## 故障排除

### 常见问题

1. **增量模式未启用**
```bash
# 检查配置
git config --get remote.origin.gcrypt-incremental-branch

# 检查当前分支
git branch --show-current
```

2. **推送失败回退到全量模式**
```bash
# 启用调试模式查看详细信息
export GCRYPT_DEBUG=1
git push origin main
```

3. **Manifest 文件损坏**
```bash
# 清理本地缓存
rm -rf .git/remote-gcrypt/cache/

# 重新获取
git fetch origin
```

### 调试命令
```bash
# 显示增量状态
GCRYPT_DEBUG=1 git-remote-gcrypt-incremental capabilities origin gcrypt::rsync://example.com/repo

# 检查远程文件
rsync -av user@host:/path/to/repo/ ./debug/
```

## 限制和注意事项

1. **分支限制**：增量模式仅支持配置的特定分支
2. **网络依赖**：需要稳定的网络连接进行协商
3. **存储格式**：新格式与原版本不完全兼容
4. **性能权衡**：首次设置可能需要额外时间

## 未来改进

1. **多分支支持**：支持多个分支的增量模式
2. **压缩优化**：改进增量包的压缩算法
3. **并行传输**：支持并行上传/下载
4. **智能缓存**：更智能的本地缓存策略