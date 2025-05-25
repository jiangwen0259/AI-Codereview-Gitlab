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

### 2. 获取项目代码

```bash
git clone https://github.com/jiangwen0259/AI-Codereview-Gitlab.git
cd AI-Codereview-Gitlab
```

### 3. 运行部署脚本

```bash
chmod +x deploy-server.sh
./deploy-server.sh
```

### 4. 配置环境变量

首次运行脚本时，会自动创建配置文件 `conf/.env`。请编辑此文件：

```bash
vi conf/.env
```

**必填配置项：**
- `DEEPSEEK_API_KEY`: DeepSeek API密钥
- `GITLAB_ACCESS_TOKEN`: GitLab访问令牌

**可选配置项：**
- `DINGTALK_WEBHOOK_URL`: 钉钉机器人Webhook地址
- `REVIEW_STYLE`: 审查风格 (professional/sarcastic/gentle/humorous)

### 5. 重新启动服务

配置完成后，重新运行部署脚本：

```bash
./deploy-server.sh
```

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