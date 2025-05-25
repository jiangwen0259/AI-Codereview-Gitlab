# 服务器部署指南

本指南专门针对x86_64架构的Linux服务器部署AI代码审查项目。

## 问题解决

### 架构不匹配问题

如果在服务器上遇到以下错误：
```
exec /usr/bin/supervisord: exec format error
```

这是因为Docker镜像架构不匹配导致的。我们已经构建了专门的AMD64架构镜像来解决这个问题。

## 快速部署

### 1. 前置条件

确保服务器已安装：
- Docker
- docker-compose
- curl (用于健康检查)
- 服务器可以访问外网（用于拉取镜像和访问AI服务）
- GitLab 可以访问到服务器（用于webhook回调）

### 2. 获取项目代码

```bash
git clone https://github.com/jiangwen0259/AI-Codereview-Gitlab.git
cd AI-Codereview-Gitlab
```

### 3. 配置环境变量

复制配置模板：
```bash
cp conf/env.server-template conf/.env
```

编辑 `conf/.env` 文件，配置以下**必需**参数：

```bash
# 大模型配置
LLM_PROVIDER=deepseek
DEEPSEEK_API_KEY=sk-your-actual-deepseek-api-key

# GitLab配置 (必需 - 缺少会导致webhook失败)
GITLAB_URL=https://your-gitlab-instance.com
GITLAB_ACCESS_TOKEN=glpat-your-actual-gitlab-token

# 支持的文件类型
SUPPORTED_EXTENSIONS=.java,.py,.php,.yml,.vue,.go,.c,.cpp,.h,.js,.css,.md,.sql
```

**重要说明：**
- `GITLAB_URL`: GitLab实例的完整URL（如：https://gitlab.com 或 https://your-gitlab.company.com）
- `GITLAB_ACCESS_TOKEN`: GitLab访问令牌，需要有项目读取权限
- 如果缺少 `GITLAB_URL` 配置，webhook调用会返回 "Missing GitLab URL" 错误

### 4. 启动服务

```bash
docker-compose up -d
```

### 5. 验证部署

检查服务状态：
```bash
docker-compose ps
```

测试API服务：
```bash
curl http://localhost:5001
# 应该返回: "The code review server is running."
```

访问Dashboard：
- 打开浏览器访问 `http://your-server-ip:5002`

### 6. 配置GitLab Webhook

在GitLab项目设置中添加Webhook：
- URL: `http://your-server-ip:5001/review/webhook`
- Trigger Events: 勾选 `Push Events` 和 `Merge Request Events`
- Secret Token: 使用上面配置的 `GITLAB_ACCESS_TOKEN`（可选）

## 服务管理

### 查看服务状态
```bash
docker-compose ps
```

### 查看日志
```bash
# 查看所有日志
docker-compose logs -f

# 查看最近50行日志
docker-compose logs --tail=50
```

### 重启服务
```bash
docker-compose restart
```

### 停止服务
```bash
docker-compose down
```

### 更新镜像
```bash
docker pull harbor.chinahuanong.com.cn/release/ai-codereview-gitlab:1.0-amd64
docker-compose down
docker-compose up -d
```

## 服务验证

部署成功后，可以通过以下方式验证：

### API服务验证
```bash
curl http://localhost:5001
# 应该返回: "The code review server is running."
```

### Dashboard验证
```bash
curl -I http://localhost:5002
# 应该返回: HTTP/1.1 200 OK
```

## 网络配置

### 防火墙设置

确保以下端口对外开放：
- 5001: API服务端口
- 5002: Dashboard端口

```bash
# CentOS/RHEL
firewall-cmd --permanent --add-port=5001/tcp
firewall-cmd --permanent --add-port=5002/tcp
firewall-cmd --reload

# Ubuntu/Debian
ufw allow 5001
ufw allow 5002
```

### Nginx反向代理 (可选)

如果需要使用域名访问，可以配置Nginx反向代理：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location /api/ {
        proxy_pass http://localhost:5001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        proxy_pass http://localhost:5002/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 故障排除

### 容器启动失败

1. 查看详细日志：
```bash
docker-compose logs app
```

2. 检查配置文件：
```bash
cat conf/.env
```

3. 检查镜像架构：
```bash
docker inspect harbor.chinahuanong.com.cn/release/ai-codereview-gitlab:1.0-amd64 | grep Architecture
```

### 服务无法访问

1. 检查端口是否被占用：
```bash
netstat -tlnp | grep -E ':(5001|5002)'
```

2. 检查防火墙设置：
```bash
iptables -L | grep -E '(5001|5002)'
```

3. 检查Docker网络：
```bash
docker network ls
docker-compose ps
```

### 配置问题

1. 验证API密钥是否正确
2. 检查GitLab访问令牌权限
3. 确认网络连接正常

## 监控和维护

### 日志轮转

建议配置日志轮转以防止日志文件过大：

```bash
# 创建logrotate配置
cat > /etc/logrotate.d/ai-codereview << EOF
/path/to/AI-Codereview-Gitlab/log/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF
```

### 定期备份

建议定期备份配置文件和数据：

```bash
# 备份脚本示例
tar -czf ai-codereview-backup-$(date +%Y%m%d).tar.gz conf/ data/ log/
```

## 技术支持

如果遇到问题，请：

1. 查看本文档的故障排除部分
2. 检查项目的GitHub Issues
3. 提供详细的错误日志和环境信息 