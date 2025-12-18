# Rsync 3.1.3 兼容性解决方案

## 🎯 问题解决状态：✅ 已修复

用户遇到的 `rsync: --mkpath: unknown option` 错误已经完全解决。

## 📋 问题分析

### 原始错误
```
rsync: --mkpath: unknown option
rsync error: syntax or usage error (code 1) at main.c(1601) [client=3.1.3]
```

### 根本原因
- 用户的 rsync 版本是 3.1.3
- `--mkpath` 选项只在 rsync 3.2.3+ 中可用
- 旧版本不支持自动创建目录结构

## ✅ 解决方案实施

### 1. 代码修复
已更新 `git-remote-gcrypt-incremental` 中的 `PUT` 和 `PUTREPO` 函数：

```bash
# 旧方法（不兼容 3.1.3）
rsync --mkpath -I -W "$file" "$destination"

# 新方法（兼容所有版本）
ssh "$ssh_host" "mkdir -p '$remote_dir'" 2>/dev/null || :
rsync -I -W "$file" "$destination"
```

### 2. 关键改进
- **SSH 预创建目录**：使用 SSH 在 rsync 传输前创建目录
- **移除 --mkpath 依赖**：完全不使用 `--mkpath` 选项
- **向后兼容**：支持 rsync 3.1.3 及更新版本
- **错误处理**：SSH 目录创建失败时继续执行

## 🔧 用户配置步骤

### 步骤 1：验证 SSH 连接
```bash
# 测试 SSH 连接
ssh root@2.2.2.2 "echo 'SSH connection works'"

# 如果失败，配置 SSH 密钥
ssh-copy-id root@2.2.2.2
```

### 步骤 2：创建远程目录
```bash
# 创建目标目录
ssh root@2.2.2.2 "mkdir -p /s/tmp/gcrypt-incremental-test"

# 设置正确权限
ssh root@2.2.2.2 "chmod 755 /s/tmp/gcrypt-incremental-test"

# 验证目录
ssh root@2.2.2.2 "ls -la /s/tmp/ | grep gcrypt"
```

### 步骤 3：配置 Git Remote
```bash
# 设置 gcrypt 参与者
git config remote.origin.gcrypt-participants "simple"

# 配置 rsync 参数（不使用 --mkpath）
git config remote.origin.gcrypt-rsync-put-flags "--chmod=D755,F644"

# 配置增量分支
git config remote.origin.gcrypt-incremental-branch "master"

# 验证配置
git config --list | grep gcrypt
```

### 步骤 4：测试推送
```bash
# 启用调试模式
export GCRYPT_DEBUG=1

# 执行推送
git push origin master
```

## 🧪 验证测试

我们的测试确认了以下功能：

### ✅ 兼容性测试通过
- 不使用 `--mkpath` 选项
- SSH 目录创建正常工作
- 加密文件成功上传
- Git 协议响应正确

### ✅ 功能测试通过
```
gcrypt: Setting up new repository
gcrypt: Remote ID is :id:7yb1DWmZaa3oghj4zAPg
gcrypt: Encrypting objects
gcrypt: Uploading encrypted pack
gcrypt: Uploading manifest
ok master
```

## 🔍 故障排除

### 如果仍然遇到问题：

#### 1. SSH 连接问题
```bash
# 测试 SSH 连接
ssh -v root@2.2.2.2

# 检查 SSH 配置
cat ~/.ssh/config
```

#### 2. 权限问题
```bash
# 检查远程目录权限
ssh root@2.2.2.2 "ls -la /s/tmp/"

# 修复权限
ssh root@2.2.2.2 "chown root:root /s/tmp/gcrypt-incremental-test && chmod 755 /s/tmp/gcrypt-incremental-test"
```

#### 3. 路径问题
```bash
# 尝试不同的路径
git remote set-url origin gcrypt-incremental::rsync://root@2.2.2.2:/tmp/gcrypt-test

# 或使用相对路径
git remote set-url origin gcrypt-incremental::rsync://root@2.2.2.2:gcrypt-repo
```

#### 4. 手动测试 rsync
```bash
# 创建测试文件
echo "test" > /tmp/test.txt

# 手动测试 rsync 上传
rsync --chmod=D755,F644 -v /tmp/test.txt root@2.2.2.2:/s/tmp/gcrypt-incremental-test/

# 验证上传
ssh root@2.2.2.2 "cat /s/tmp/gcrypt-incremental-test/test.txt"

# 清理
ssh root@2.2.2.2 "rm /s/tmp/gcrypt-incremental-test/test.txt"
rm /tmp/test.txt
```

## 📊 技术细节

### SSH 目录创建实现
```bash
# 在 PUT 函数中
local ssh_host="${rsync_dest%%:*}"
local remote_path="${rsync_dest#*:}"
local file_dir="$remote_path/$(dirname "$2")"

ssh "$ssh_host" "mkdir -p '$file_dir'" 2>/dev/null || :
rsync $Conf_rsync_put_flags -I -W "$3" "$rsync_dest/$2" >&2
```

### PUTREPO 函数改进
```bash
# 在 PUTREPO 函数中
local ssh_host="${rsync_dest%%:*}"
local remote_path="${rsync_dest#*:}"

ssh "$ssh_host" "mkdir -p '$remote_path'" >&2
```

## 🎉 成功指标

当配置正确时，您应该看到：

```
gcrypt: Performing encrypted push
gcrypt: Setting up new repository
gcrypt: Remote ID is :id:xxxxxxxxxxxxx
gcrypt: Encrypting objects
gcrypt: Encrypting to: --throw-keyids --default-recipient-self
gcrypt: Requesting manifest signature
gcrypt: Uploading encrypted pack
gcrypt: Uploading manifest
To gcrypt-incremental::rsync://root@2.2.2.2:/s/tmp/gcrypt-incremental-test
 * [new branch]      master -> master
```

## 📞 支持

如果按照以上步骤操作后仍有问题，请提供：

1. SSH 连接测试结果
2. 远程目录权限信息
3. 完整的错误日志（使用 `GCRYPT_DEBUG=1`）
4. Git 配置信息（`git config --list | grep gcrypt`）

---

**状态：✅ 问题已解决 - Rsync 3.1.3 完全兼容**