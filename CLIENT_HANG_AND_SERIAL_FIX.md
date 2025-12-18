# 客户端卡住和序列号问题修复

## 问题描述

在第一次推送修复后，发现了两个新问题：

1. **客户端卡住不退出** - 推送完成后客户端一直等待，没有正常退出
2. **序列号重复问题** - pack和manifest使用了相同的序列号，且缺少基础manifest (serial 0)

## 问题分析

### 问题1：客户端卡住
- **原因**：`do_incremental_push`函数没有发送Git协议要求的响应消息
- **Git协议要求**：每个成功的refspec都需要返回`ok <ref>`响应，最后以空行结束

### 问题2：序列号问题
- **原因**：pack和manifest使用了相同的序列号计算逻辑
- **缺失**：没有创建基础manifest (serial 0) 来初始化增量模式

## 修复方案

### 修复1：添加Git协议响应

在`do_incremental_push`函数结尾添加：

```bash
# Step 12: Send Git protocol responses
local r_args="$1"
if [ -n "$r_args" ]; then
    # Parse refspecs and send success responses
    while IFS=: read -r src_ dst_; do
        src_=${src_#+}
        echo_git "ok $dst_"
    done <<EOF
$r_args
EOF
fi

# Send final empty line to complete Git protocol
echo_git
```

### 修复2：序列号分离和基础manifest

1. **创建基础manifest (serial 0)**：
```bash
# Create base manifest (serial 0) for initial setup
local base_manifest="$Tempdir/base_manifest"
echo "version: $Incremental_version" > "$base_manifest"
echo "timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$base_manifest"
echo "repository_id: $Repoid" >> "$base_manifest"
echo "initial_setup: true" >> "$base_manifest"

# Upload with serial 0
base_manifest_filename=$(generate_incremental_filename "0" "$(cat "$base_manifest_encrypted")")
```

2. **分离pack和manifest序列号**：
```bash
# Pack uses serial + 1
local pack_serial=$((Remote_manifest_serial + 1))
new_filename=$(generate_incremental_filename "$pack_serial" "$(cat "$tmp_encrypted")")

# Manifest uses serial + 2 (different from pack)
local manifest_serial=$((Remote_manifest_serial + 2))
manifest_filename=$(generate_incremental_filename "$manifest_serial" "$(cat "$manifest_encrypted")")
```

## 修复结果

### 修复前的问题日志：
```
gcrypt: Uploading incremental pack: 0000000000000001-[hash]
gcrypt: Uploading new manifest: 0000000000000001-[hash]  # 相同序列号！
gcrypt: Incremental push completed successfully
# 客户端卡住，没有退出
```

### 修复后的正确行为：
```
gcrypt: Uploading base manifest: 0000000000000000-[hash]      # 基础manifest
gcrypt: Uploading incremental pack: 0000000000000001-[hash]   # pack序列号
gcrypt: Uploading new manifest: 0000000000000002-[hash]       # manifest序列号
ok refs/heads/my                                              # Git协议响应
gcrypt: Incremental push completed successfully
# 客户端正常退出
```

## 文件结构

修复后，远程仓库将包含：

1. **0000000000000000-[hash]** - 基础manifest，包含仓库初始化信息
2. **0000000000000001-[hash]** - 增量pack文件，包含实际的Git对象
3. **0000000000000002-[hash]** - 提交manifest，包含提交信息和pack引用

## 验证测试

测试结果显示：
- ✅ 客户端不再卡住，正常退出
- ✅ 创建了基础manifest (serial 0)
- ✅ Pack和manifest使用不同的序列号
- ✅ 发送了正确的Git协议响应

## 技术要点

1. **Git协议兼容性**：必须发送`ok <ref>`响应和结束空行
2. **序列号管理**：不同类型的文件应使用不同的序列号
3. **初始化完整性**：基础manifest确保增量模式的正确初始化
4. **错误处理**：保持与原始gcrypt的兼容性

这些修复确保了增量模式在第一次推送时的完整性和正确性。