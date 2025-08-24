# Ansible 项目安全指南

本文档描述了如何在 Ansible 项目中安全地管理密钥、密码和其他敏感信息。

## 目录结构

```
ansible/
├── vault/                      # Ansible Vault 加密文件
│   ├── README.md              # Vault 使用说明
│   ├── production_secrets.yml # 生产环境敏感变量 (加密)
│   ├── staging_secrets.yml    # 预生产环境敏感变量 (加密)
│   └── example_secrets.yml    # 示例文件 (未加密)
├── keys/                      # SSH 密钥文件
│   ├── README.md              # 密钥管理说明
│   ├── production/            # 生产环境密钥
│   ├── staging/               # 预生产环境密钥
│   └── development/           # 开发环境密钥
├── secrets/                   # 其他敏感配置
│   ├── README.md              # 配置说明
│   ├── credentials.yml.template    # 凭据模板
│   ├── database.yml.template      # 数据库配置模板
│   ├── api_keys.yml.template      # API密钥模板
│   └── ssl/                   # SSL 证书和私钥
│       ├── certificates/      # 证书文件
│       └── private_keys/      # 私钥文件
├── .gitignore                 # Git 忽略文件
└── SECURITY.md               # 本安全指南
```

## 安全最佳实践

### 1. Ansible Vault 使用
```bash
# 创建新的加密文件
ansible-vault create vault/production_secrets.yml

# 编辑现有加密文件
ansible-vault edit vault/production_secrets.yml

# 加密现有文件
ansible-vault encrypt secrets/credentials.yml

# 解密文件 (仅用于查看)
ansible-vault view vault/production_secrets.yml
```

### 2. SSH 密钥管理
- 为不同环境使用不同的SSH密钥
- 设置正确的文件权限：`chmod 600 keys/*.pem`
- 定期轮换SSH密钥
- 使用强密码保护私钥

### 3. 密码策略
- 使用强密码（至少16位，包含大小写字母、数字、特殊字符）
- 定期更换密码（建议每90天）
- 不要在多个服务间重复使用密码
- 使用密码管理器生成和存储密码

### 4. 文件权限
```bash
# 设置正确的目录权限
chmod 700 vault/ keys/ secrets/
chmod 600 vault/*.yml
chmod 600 keys/*.pem keys/*.key
chmod 600 secrets/*.yml
```

### 5. 版本控制安全
- `.gitignore` 文件已配置排除所有敏感文件
- 只提交模板文件（`.template` 后缀）
- 定期审查提交历史，确保没有意外提交敏感信息

## 环境变量

建议使用环境变量来管理 Vault 密码：

```bash
# 设置 Vault 密码文件
export ANSIBLE_VAULT_PASSWORD_FILE=.vault_pass

# 或直接设置密码 (不推荐用于生产)
export ANSIBLE_VAULT_PASSWORD=your_vault_password
```

## 运行 Playbook

```bash
# 使用 Vault 密码提示
ansible-playbook -i inventory/hosts.yml site.yml --ask-vault-pass

# 使用密码文件
ansible-playbook -i inventory/hosts.yml site.yml --vault-password-file .vault_pass

# 限制目标主机
ansible-playbook -i inventory/hosts.yml site.yml --limit production --ask-vault-pass
```

## 应急响应

如果密钥或密码泄露：

1. **立即行动**
   - 更改所有相关密码
   - 撤销泄露的SSH密钥
   - 轮换API密钥

2. **审计检查**
   - 检查访问日志
   - 审查最近的系统活动
   - 确认没有未授权访问

3. **更新配置**
   - 使用新密钥重新加密 Vault 文件
   - 更新所有相关系统的配置
   - 测试所有服务的正常运行

## 合规性

- 定期进行安全审计
- 记录所有密钥更换活动
- 保持最新的安全补丁
- 遵循公司的安全政策和合规要求

## 联系方式

如有安全问题或需要帮助，请联系：
- 安全团队：security@company.com
- 系统管理员：admin@company.com
