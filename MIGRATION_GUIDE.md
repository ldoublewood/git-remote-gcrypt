# Git Remote Gcrypt - 迁移指南

## 从原版本迁移到增量版本

本指南帮助您将现有的 git-remote-gcrypt 仓库迁移到支持增量推送的新版本。

## 迁移前准备

### 1. 备份现有仓库
```bash
# 备份本地仓库
cp -r /path/to/your/repo /path/to/backup/repo

# 备份远程加密仓库
rsync -av user@host:/path/to/remote/repo/ ./remote_backup/
```

### 2. 检查当前配置
```bash
# 查看现有配置
git config --list | grep gcrypt

# 查看远程仓库信息
git remote -v
```

### 3. 验证 GPG 设置
```bash
# 确认 GPG 密钥可用
gpg --list-secret-keys

# 测试加密/解密
echo "test" | gpg --encrypt --armor -r YOUR_KEY_ID | gpg --decrypt
```

## 迁移步骤

### 阶段 1：安装增量版本

#### 1.1 安装新版本
```bash
# 备份原版本
sudo cp /usr/local/bin/git-remote-gcrypt /usr/local/bin/git-remote-gcrypt.backup

# 安装增量版本
sudo cp git-remote-gcrypt-incremental /usr/local/bin/git-remote-gcrypt-incremental
sudo chmod +x /usr/local/bin/git-remote-gcrypt-incremental

# 创建符号链接（可选）
sudo ln -sf /usr/local/bin/git-remote-gcrypt-incremental /usr/local/bin/git-remote-gcrypt
```

#### 1.2 验证安装
```bash
# 测试新版本
git-remote-gcrypt-incremental --help 2>/dev/null || echo "Installation successful"
```

### 阶段 2：配置增量模式

#### 2.1 选择增量分支
```bash
# 为主分支启用增量模式
git config remote.origin.gcrypt-incremental-branch "main"

# 或为开发分支启用
git config remote.origin.gcrypt-incremental-branch "develop"
```

#### 2.2 保持现有配置
```bash
# 现有配置会自动继承
# 无需修改以下配置：
# - remote.origin.gcrypt-participants
# - gcrypt.gpg-args
# - user.signingkey
```

### 阶段 3：渐进式迁移

#### 3.1 混合模式运行
```bash
# 增量分支使用新模式
git checkout main
git push origin main  # 使用增量模式

# 其他分支继续使用原模式
git checkout feature-branch
git push origin feature-branch  # 使用原模式
```

#### 3.2 验证增量功能
```bash
# 启用调试模式
export GCRYPT_DEBUG=1

# 进行测试推送
echo "test change" >> README.md
git add README.md
git commit -m "Test incremental push"
git push origin main

# 检查输出中的增量信息
```

### 阶段 4：完整迁移（可选）

#### 4.1 迁移所有分支
```bash
# 逐个迁移其他重要分支
git config remote.origin.gcrypt-incremental-branch "main,develop,release"
```

#### 4.2 清理旧格式文件
```bash
# 注意：这会删除旧格式的远程文件
# 确保所有客户端都已升级后再执行

# 列出远程文件
rsync -av --dry-run user@host:/path/to/remote/repo/ ./

# 识别旧格式文件（非增量命名格式）
# 手动清理或使用脚本清理
```

## 兼容性策略

### 1. 向后兼容
- 非增量分支继续使用原格式
- 原有客户端可以继续访问非增量分支
- 新客户端可以处理两种格式

### 2. 混合环境
```bash
# 团队中部分成员使用新版本
# 配置策略：
git config remote.origin.gcrypt-incremental-branch "main"  # 仅主分支增量

# 其他分支保持兼容
git checkout feature-branch
git push origin feature-branch  # 原格式，兼容旧客户端
```

### 3. 渐进升级
```bash
# 第一周：仅配置，不启用
git config remote.origin.gcrypt-incremental-branch ""

# 第二周：启用主分支
git config remote.origin.gcrypt-incremental-branch "main"

# 第三周：添加更多分支
git config remote.origin.gcrypt-incremental-branch "main,develop"
```

## 故障排除

### 1. 迁移失败回滚
```bash
# 恢复原版本
sudo cp /usr/local/bin/git-remote-gcrypt.backup /usr/local/bin/git-remote-gcrypt

# 清除增量配置
git config --unset remote.origin.gcrypt-incremental-branch

# 验证原功能
git push origin main
```

### 2. 配置冲突解决
```bash
# 检查配置冲突
git config --list | grep gcrypt | sort

# 重置有问题的配置
git config --unset remote.origin.gcrypt-incremental-branch
git config remote.origin.gcrypt-incremental-branch "main"
```

### 3. 性能问题诊断
```bash
# 启用详细日志
export GCRYPT_DEBUG=1
export GCRYPT_VERBOSE=1

# 分析推送性能
time git push origin main

# 检查网络和磁盘 I/O
iostat -x 1 &
git push origin main
killall iostat
```

## 验证迁移成功

### 1. 功能验证
```bash
# 测试增量推送
git checkout main
echo "migration test" >> MIGRATION_TEST.md
git add MIGRATION_TEST.md
git commit -m "Migration verification"
git push origin main

# 应该看到增量模式的日志信息
```

### 2. 性能验证
```bash
# 比较推送时间
# 原版本：记录完整推送时间
# 新版本：记录增量推送时间

# 比较传输数据量
# 使用网络监控工具观察实际传输量
```

### 3. 完整性验证
```bash
# 克隆验证
cd /tmp
git clone gcrypt::user@host:/path/to/repo test-clone
cd test-clone

# 验证历史完整性
git log --oneline
git fsck
```

## 最佳实践

### 1. 分阶段迁移
- 先在测试环境验证
- 选择低风险分支开始
- 逐步扩展到主要分支

### 2. 监控和回滚
- 保持原版本备份
- 监控推送性能
- 准备快速回滚方案

### 3. 团队协调
- 通知团队成员升级计划
- 提供迁移文档和支持
- 建立问题反馈机制

## 常见问题

### Q: 迁移后原有的远程仓库还能访问吗？
A: 是的，非增量分支继续使用原格式，完全兼容。

### Q: 如果团队中有人还在使用旧版本怎么办？
A: 可以配置仅部分分支使用增量模式，其他分支保持兼容。

### Q: 迁移失败如何回滚？
A: 恢复原版本文件，清除增量配置，即可回到原状态。

### Q: 增量模式会影响安全性吗？
A: 不会，加密和签名机制保持不变，仅优化了传输效率。

### Q: 如何确认迁移成功？
A: 检查推送日志中的增量信息，验证传输数据量减少。

## 支持和帮助

如果在迁移过程中遇到问题：

1. 查看详细日志：`export GCRYPT_DEBUG=1`
2. 运行测试脚本：`./test_incremental.sh`
3. 检查配置：`git config --list | grep gcrypt`
4. 验证 GPG 设置：`gpg --list-keys`

迁移成功后，您将享受到显著的性能提升和存储优化！