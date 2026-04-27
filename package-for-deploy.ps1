# 打包项目用于部署到服务器
# 使用方法: .\package-for-deploy.ps1

Write-Host "开始打包项目..." -ForegroundColor Green

# 设置输出文件名
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFile = "crowdsource-backend-deploy-$timestamp.tar.gz"

# 需要排除的文件和目录
$excludeItems = @(
    "target",
    ".idea",
    ".vscode",
    "*.log",
    "*.iml",
    ".git",
    "test-api.ps1",
    "package-for-deploy.ps1"
)

Write-Host "正在打包，排除以下内容: $($excludeItems -join ', ')" -ForegroundColor Yellow

# 使用 tar 打包（需要 Windows 10 1803+ 或安装 Git Bash）
$excludeArgs = $excludeItems | ForEach-Object { "--exclude=$_" }

try {
    # 切换到上级目录
    Push-Location ..
    
    # 执行打包
    $cmd = "tar -czf `"$outputFile`" $($excludeArgs -join ' ') crowdsource-backend/"
    Invoke-Expression $cmd
    
    if (Test-Path $outputFile) {
        $fileSize = (Get-Item $outputFile).Length / 1MB
        Write-Host "`n打包成功！" -ForegroundColor Green
        Write-Host "文件: $outputFile" -ForegroundColor Cyan
        Write-Host "大小: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Cyan
        Write-Host "`n上传到服务器命令:" -ForegroundColor Yellow
        Write-Host "scp $outputFile root@your-server-ip:/opt/" -ForegroundColor White
        Write-Host "`n服务器解压命令:" -ForegroundColor Yellow
        Write-Host "cd /opt && tar -xzf $outputFile" -ForegroundColor White
    } else {
        Write-Host "打包失败！" -ForegroundColor Red
    }
} catch {
    Write-Host "打包过程出错: $_" -ForegroundColor Red
} finally {
    Pop-Location
}

Write-Host "`n提示: 上传前请确保已修改 docker-compose.yml 中的密码和密钥！" -ForegroundColor Yellow
