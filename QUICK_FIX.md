# 🚀 快速修复 Rsync 兼容性问题

## 问题
```
rsync: --mkpath: unknown option
rsync error: syntax or usage error (code 1)
```

## 🎯 快速解决方案 (已修复)

脚本已更新，不再使用 `--mkpath` 选项，兼容所有 rsync 版本。

### 方法 1: 确保远程目录存在 (推荐)

```bash
# 1. 在远程服务器创建目录并设置权限
ssh root@2.2.2.2 "mkdir -p /s/tmp/gcrypt-incremental-test && chmod 755 /s/tmp/gcrypt-incremental-test"

# 2. 配置 rsync 参数 (移除可能有问题的选项)
git config remote.origin.gcrypt-rsync-put-flags "--chmod=D755,F644"

# 3. 重新推送
export GCRYPT_DEBUG=1
git push origin master
```

### 方法 2: 使用不同路径

```bash
# 使用用户主目录 (更安全)
git remote set-url origin gcrypt-incremental::rsync://root@2.2.2.2:gcrypt-repo

# 推送
git push origin master
```

### 方法 3: 使用自动修复脚本

```bash
# 运行自动修复脚本
./fix_rsync_permissions.sh
```

## ✅ 验证修复

推送成功后应该看到：
```
gcrypt: Uploading encrypted pack
gcrypt: Uploading manifest
To gcrypt-incremental::rsync://root@2.2.2.2:/path
 * [new branch]      master -> master
```

## 🔍 如果还有问题

1. **检查 SSH 连接**: `ssh root@2.2.2.2 "echo test"`
2. **检查目录权限**: `ssh root@2.2.2.2 "ls -la /s/tmp/"`
3. **测试 rsync**: `echo test > /tmp/test && rsync /tmp/test root@2.2.2.2:/tmp/`

大多数情况下方法 1 就能解决问题！