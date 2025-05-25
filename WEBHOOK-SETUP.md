# Webhook配置指南

## 问题解决：HTTP 400 "Missing GitLab URL"

### 问题原因
webhook调用返回 `{"message":"Missing GitLab URL"}` 错误是因为配置文件中缺少 `GITLAB_URL` 参数。

### 解决方案

#### 1. 更新配置文件
在服务器上编辑 `conf/.env` 文件，确保包含以下必需配置：

```bash
# GitLab配置 (必需)
GITLAB_URL=https://your-gitlab-instance.com
GITLAB_ACCESS_TOKEN=glpat-your-actual-token

# 大模型配置
LLM_PROVIDER=deepseek
DEEPSEEK_API_KEY=sk-your-actual-api-key
```

#### 2. 重启服务
```bash
docker-compose restart
```

#### 3. 验证修复
测试webhook端点：
```bash
curl -X POST http://your-server:5001/review/webhook \
  -H "Content-Type: application/json" \
  -d '{"object_kind":"push","repository":{"homepage":"https://gitlab.example.com/test/project"},"project":{"id":123}}'
```

成功响应应该是：
```json
{"message":"Request received(object_kind=push), will process asynchronously."}
```

## 完整配置步骤

### 1. GitLab配置

#### 获取GitLab URL
- 如果使用 gitlab.com: `GITLAB_URL=https://gitlab.com`
- 如果使用私有GitLab: `GITLAB_URL=https://your-gitlab-domain.com`

#### 创建Access Token
1. 进入GitLab项目 → Settings → Access Tokens
2. 创建新token，权限选择：
   - `read_api`
   - `read_repository` 
   - `write_repository` (用于添加评论)
3. 复制生成的token

### 2. DeepSeek API配置

#### 获取API密钥
1. 访问 [DeepSeek开放平台](https://platform.deepseek.com/)
2. 注册/登录账号
3. 创建API密钥
4. 确保账户有足够余额

### 3. 配置GitLab Webhook

在GitLab项目中设置webhook：

1. 进入项目 → Settings → Webhooks
2. 配置参数：
   - **URL**: `http://your-server-ip:5001/review/webhook`
   - **Secret Token**: 使用上面的GitLab Access Token（可选）
   - **Trigger Events**: 勾选
     - ✅ Push events
     - ✅ Merge request events
     - ❌ 其他事件不要勾选
3. 点击 "Add webhook"

### 4. 测试配置

#### 测试webhook连接
在GitLab webhook设置页面点击 "Test" → "Push events"

#### 检查服务日志
```bash
docker-compose logs -f app
```

正常日志应该显示：
```
INFO - Received event: push
INFO - Push Hook event received
```

## 常见问题排查

### 1. 仍然返回"Missing GitLab URL"
- 检查 `conf/.env` 文件是否包含 `GITLAB_URL=...`
- 确认已重启服务: `docker-compose restart`
- 检查配置文件格式，确保没有多余空格

### 2. API认证失败
```
ERROR - DeepSeek API error: Authentication Fails
```
- 检查 `DEEPSEEK_API_KEY` 是否正确
- 确认API密钥有效且有余额
- 检查网络连接

### 3. GitLab无法访问webhook
- 确保服务器端口5001对外开放
- 检查防火墙设置
- 如果是内网环境，确保GitLab可以访问服务器

### 4. Webhook超时
- 检查服务器性能和网络延迟
- 考虑增加GitLab webhook超时设置

## 配置示例

完整的 `conf/.env` 配置示例：

```bash
# 大模型配置
LLM_PROVIDER=deepseek
DEEPSEEK_API_KEY=sk-1234567890abcdef1234567890abcdef
DEEPSEEK_API_MODEL=deepseek-coder

# GitLab配置 (必需)
GITLAB_URL=https://gitlab.example.com
GITLAB_ACCESS_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx

# 支持的文件类型
SUPPORTED_EXTENSIONS=.java,.py,.php,.yml,.vue,.go,.c,.cpp,.h,.js,.css,.md,.sql

# 消息推送（可选）
DINGTALK_ENABLED=0
DINGTALK_WEBHOOK_URL=

# 审查风格（可选）
REVIEW_STYLE=professional
```

## 验证部署成功

1. **API服务**: `curl http://your-server:5001` 返回服务运行信息
2. **Dashboard**: 访问 `http://your-server:5002` 看到界面
3. **Webhook**: GitLab测试webhook返回200状态码
4. **日志**: `docker-compose logs app` 显示正常启动信息

配置完成后，当有代码推送或合并请求时，系统会自动进行代码审查并在GitLab中添加评论。 