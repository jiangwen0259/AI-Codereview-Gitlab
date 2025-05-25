#!/bin/bash

# AI代码审查项目服务器部署脚本
# 适用于x86_64架构的Linux服务器

echo "=== AI代码审查项目服务器部署 ==="

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装，请先安装Docker"
    exit 1
fi

# 检查docker-compose是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose未安装，请先安装docker-compose"
    exit 1
fi

# 停止现有容器
echo "🛑 停止现有容器..."
docker-compose down

# 拉取最新镜像
echo "📥 拉取最新镜像..."
docker pull harbor.chinahuanong.com.cn/release/ai-codereview-gitlab:1.0-amd64

# 创建必要的目录
echo "📁 创建必要的目录..."
mkdir -p log data conf

# 检查配置文件
if [ ! -f "conf/.env" ]; then
    echo "⚠️  配置文件 conf/.env 不存在"
    if [ -f "conf/env.server-template" ]; then
        echo "📋 发现配置模板文件，正在复制..."
        cp conf/env.server-template conf/.env
        echo "✅ 配置文件已创建: conf/.env"
        echo "⚠️  请编辑 conf/.env 文件，填写实际的配置值："
        echo "   - DEEPSEEK_API_KEY (或其他LLM的API密钥)"
        echo "   - GITLAB_ACCESS_TOKEN"
        echo "   - 其他可选配置"
        echo ""
        echo "配置完成后，重新运行此脚本"
        exit 1
    else
        echo "❌ 配置模板文件不存在，请参考README.md中的配置说明"
        exit 1
    fi
fi

# 启动服务
echo "🚀 启动服务..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 15

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose ps

# 测试服务
echo "🧪 测试服务..."
if curl -s http://localhost:5001 > /dev/null; then
    echo "✅ API服务启动成功 - http://localhost:5001"
else
    echo "❌ API服务启动失败，查看日志: docker-compose logs app"
fi

if curl -s http://localhost:5002 > /dev/null; then
    echo "✅ Dashboard服务启动成功 - http://localhost:5002"
else
    echo "❌ Dashboard服务启动失败，查看日志: docker-compose logs app"
fi

echo ""
echo "=== 部署完成 ==="
echo "API服务地址: http://your-server-ip:5001"
echo "Dashboard地址: http://your-server-ip:5002"
echo ""
echo "常用命令:"
echo "  查看日志: docker-compose logs -f"
echo "  停止服务: docker-compose down"
echo "  重启服务: docker-compose restart"
echo "  查看状态: docker-compose ps" 