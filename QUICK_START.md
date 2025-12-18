# Git Remote Gcrypt Incremental - 快速开始指南

## 🚀 5 分钟快速配置

### 前提条件
- ✅ Git 已安装
- ✅ GPG 已安装
- ✅ SSH 访问远程服务器
- ✅ Rsync 已安装（任何版本，包括 3.1.3）

### 步骤 1：安装脚本
```bash
# 复制脚本到 PATH 中的目录
sudo cp git-remote-gcrypt-incremental /usr/local/bin/
sudo chmod +x /usr/local/bin/git-remote-gcrypt-incremental

# 或者添加到当前项目
cp git-remote-gcrypt-incremental /path/to/your/repo/
chmod +x /path/to/your/repo/git-remote-gcrypt-incremental
```

### 步骤 2：准备远程服务器
```bash
# 替换为您的实际服务器信息
REMOTE_USER="root"
REMOTE_HOST="2.2.2.2"
REMOTE_PATH="/s/tmp/gcrypt-incremental-test"

# 测试 SSH 连接
ssh ${REMOTE_USER}@${REMOTE_HOST} "echo 'SSH works'"

# 创建远程目录
ssh ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_PATH} && chmod 755 ${REMOTE_PATH}"
```

### 步骤 3：配置 Git 仓库
```bash
# 进入您的 Git 仓库
cd /path/to/your/repo

# 添加加密远程仓库
git remote add origin gcrypt-incremental::rsync://${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}

# 配置加密参数
git config remote.origin.gcrypt-participants "simple"

# 配置 rsync 参数（兼容 rsync 3.1.3）
git config remote.origin.gcrypt-rsync-put-flags "--chmod=D755,F644"

# 配置增量推送分支
git config remote.origin.gcrypt-incremental-branch "master"
```

### 步骤 4：首次推送
```bash
# 启用调试模式（可选，用于查看详细信息）
export GCRYPT_DEBUG=1

# 推送到远程仓库
git push origin master
```

## ✅ 成功标志

如果配置正确，您应该看到类似输出：

```
gcrypt: Performing encrypted push
gcrypt: Setting up new repository
gcrypt: Remote ID is :id:xxxxxxxxxxxxx
gcrypt: Encrypting objects
gcrypt: Uploading encrypted pack
gcrypt: Uploading manifest
To gcrypt-incremental::rsync://root@2.2.2.2:/s/tmp/gcrypt-incremental-test
 * [new branch]      master -> master
```

## 🔧 常用命令

### 查看配置
```bash
git config --list | grep gcrypt
git remote -v
```

### 推送更新
```bash
git push origin master
```

### 拉取更新
```bash
git pull origin master
```

### 调试模式
```bash
export GCRYPT_DEBUG=1
git push origin master
```

## ⚠️ 常见问题

### 问题 1：SSH 连接失败
```bash
# 解决方案：配置 SSH 密钥
ssh-keygen -t rsa -b 4096
ssh-copy-id ${REMOTE_USER}@${REMOTE_HOST}
```

### 问题 2：权限被拒绝
```bash
# 解决方案：修复远程目录权限
ssh ${REMOTE_USER}@${REMOTE_HOST} "chmod 755 ${REMOTE_PATH}"
```

### 问题 3：rsync --mkpath 错误
```bash
# 解决方案：确保使用正确的 rsync 参数
git config remote.origin.gcrypt-rsync-put-flags "--chmod=D755,F644"
# 注意：不要包含 --mkpath 选项
```

### 问题 4：GPG 错误
```bash
# 解决方案：使用 simple 模式（不需要特定 GPG 密钥）
git config remote.origin.gcrypt-participants "simple"
```

## 📋 配置检查清单

在推送前，确认以下配置：

- [ ] SSH 连接正常：`ssh ${REMOTE_USER}@${REMOTE_HOST} "echo OK"`
- [ ] 远程目录存在：`ssh ${REMOTE_USER}@${REMOTE_HOST} "ls -la ${REMOTE_PATH}"`
- [ ] Git remote 配置：`git remote -v`
- [ ] Gcrypt 参与者：`git config --get remote.origin.gcrypt-participants`
- [ ] Rsync 参数：`git config --get remote.origin.gcrypt-rsync-put-flags`
- [ ] 增量分支：`git config --get remote.origin.gcrypt-incremental-branch`

## 🎯 一键配置脚本

将以下内容保存为 `setup-gcrypt.sh`：

```bash
#!/bin/bash

# 配置参数
REMOTE_USER="root"
REMOTE_HOST="2.2.2.2"
REMOTE_PATH="/s/tmp/gcrypt-incremental-test"
BRANCH="master"

echo "🔧 配置 Git Remote Gcrypt Incremental"
echo "====================================="

# 测试 SSH
echo "测试 SSH 连接..."
if ssh ${REMOTE_USER}@${REMOTE_HOST} "echo 'SSH OK'"; then
    echo "✅ SSH 连接成功"
else
    echo "❌ SSH 连接失败"
    exit 1
fi

# 创建远程目录
echo "创建远程目录..."
ssh ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_PATH} && chmod 755 ${REMOTE_PATH}"
echo "✅ 远程目录已创建"

# 配置 Git
echo "配置 Git 远程仓库..."
git remote remove origin 2>/dev/null || true
git remote add origin "gcrypt-incremental::rsync://${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}"
git config remote.origin.gcrypt-participants "simple"
git config remote.origin.gcrypt-rsync-put-flags "--chmod=D755,F644"
git config remote.origin.gcrypt-incremental-branch "${BRANCH}"

echo "✅ Git 配置完成"
echo
echo "配置摘要："
echo "  Remote URL: $(git config --get remote.origin.url)"
echo "  Participants: $(git config --get remote.origin.gcrypt-participants)"
echo "  Rsync flags: $(git config --get remote.origin.gcrypt-rsync-put-flags)"
echo "  Incremental branch: $(git config --get remote.origin.gcrypt-incremental-branch)"
echo
echo "🎉 配置完成！现在可以执行："
echo "  git push origin ${BRANCH}"
```

使用方法：
```bash
chmod +x setup-gcrypt.sh
./setup-gcrypt.sh
```

## 📚 更多信息

- 详细文档：`README_INCREMENTAL.md`
- 故障排除：`RSYNC_TROUBLESHOOTING.md`
- Rsync 3.1.3 解决方案：`RSYNC_3.1.3_SOLUTION.md`
- 项目摘要：`PROJECT_SUMMARY.md`

---

**准备好了吗？开始使用加密的 Git 远程仓库！** 🚀