[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$base = "http://localhost:8080"
$ct = @{ "Content-Type" = "application/json; charset=utf-8" }
$pass = 0; $fail = 0
$mysqlBin = "E:\Mysql\mysql-5.7.38-winx64\bin\mysql.exe"

function Check($name, $resp, $expectCode = 200) {
    if ($resp.code -eq $expectCode) {
        Write-Host "[PASS] $name" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "[FAIL] $name => code=$($resp.code) msg=$($resp.message)" -ForegroundColor Red
        $script:fail++
    }
    return $resp
}

function AuthHeader($token) {
    return @{ "Content-Type" = "application/json; charset=utf-8"; "Authorization" = "Bearer $token" }
}

# 用 UTF-8 文件传 body，避免 PowerShell 中文编码问题
function PostJson($url, $body, $headers) {
    $tmp = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tmp, $body, [System.Text.Encoding]::UTF8)
    $bytes = [System.IO.File]::ReadAllBytes($tmp)
    Remove-Item $tmp
    return Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $bytes
}

function PutJson($url, $body, $headers) {
    $tmp = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tmp, $body, [System.Text.Encoding]::UTF8)
    $bytes = [System.IO.File]::ReadAllBytes($tmp)
    Remove-Item $tmp
    return Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $bytes
}

# ===== 1. 获取标签 =====
$r = Invoke-RestMethod -Uri "$base/api/tags" -Method GET
Check "GET /api/tags" $r | Out-Null

# ===== 2. 发单人登录（微信模拟）=====
$r = PostJson "$base/api/auth/login" '{"loginType":"wechat","code":"pub001"}' $ct
Check "POST /api/auth/login (发单人)" $r | Out-Null
$pubToken = $r.data.token; $pubId = $r.data.userId
Write-Host "  发单人 userId=$pubId"

# ===== 3. 接单人登录 =====
$r = PostJson "$base/api/auth/login" '{"loginType":"wechat","code":"worker001"}' $ct
Check "POST /api/auth/login (接单人)" $r | Out-Null
$workerToken = $r.data.token; $workerId = $r.data.userId
Write-Host "  接单人 userId=$workerId"

# ===== 4. 更新发单人资料 =====
$r = PutJson "$base/api/user/profile" '{"nickname":"张三发单","role":2}' (AuthHeader $pubToken)
Check "PUT /api/user/profile (发单人)" $r | Out-Null

# ===== 5. 更新接单人资料 =====
$body = '{"nickname":"李四接单","role":3,"techStack":["Java","Spring Boot"],"skillTags":[1,8],"priceMin":500,"priceMax":5000,"preferTypes":["开发"]}'
$r = PutJson "$base/api/user/profile" $body (AuthHeader $workerToken)
Check "PUT /api/user/profile (接单人)" $r | Out-Null

# ===== 6. 获取当前用户信息 =====
$r = Invoke-RestMethod -Uri "$base/api/user/me" -Method GET -Headers (AuthHeader $pubToken)
Check "GET /api/user/me" $r | Out-Null

# ===== 7. 发布任务 =====
$taskBody = '{"title":"开发一个电商小程序","description":"需要完整的前后端开发，包含用户、商品、订单模块","type":"开发","budgetMin":3000,"budgetMax":8000,"tagIds":[1,8,11]}'
$r = PostJson "$base/api/tasks" $taskBody (AuthHeader $pubToken)
Check "POST /api/tasks (发布任务)" $r | Out-Null
$taskId = $r.data
Write-Host "  taskId=$taskId"

# ===== 8. 查询任务列表（待审核）=====
$r = Invoke-RestMethod -Uri "$base/api/tasks?status=1" -Method GET -Headers (AuthHeader $pubToken)
Check "GET /api/tasks?status=1 (待审核)" $r | Out-Null

# ===== 9. 管理员登录并设置角色 =====
$r = PostJson "$base/api/auth/login" '{"loginType":"wechat","code":"admin001"}' $ct
Check "POST /api/auth/login (管理员)" $r | Out-Null
$adminId = $r.data.userId
# 直接 SQL 设置管理员角色
& $mysqlBin -uroot -p123456 crowdsource -e "UPDATE user SET role=1 WHERE id=$adminId;" 2>$null
# 重新登录
$r = PostJson "$base/api/auth/login" '{"loginType":"wechat","code":"admin001"}' $ct
$adminToken = $r.data.token
Write-Host "  管理员 userId=$adminId"

# ===== 10. 管理员审核任务 =====
$r = Invoke-RestMethod -Uri "$base/api/admin/tasks/$taskId/review?approve=true" -Method POST -Headers (AuthHeader $adminToken)
Check "POST /api/admin/tasks/{id}/review (通过)" $r | Out-Null

# ===== 11. 查询招募中任务 =====
$r = Invoke-RestMethod -Uri "$base/api/tasks?status=2" -Method GET -Headers (AuthHeader $workerToken)
Check "GET /api/tasks?status=2 (招募中)" $r | Out-Null

# ===== 12. 接单人申请接单 =====
$applyBody = '{"message":"我有3年Java开发经验，可以完成此任务","price":5000}'
$r = PostJson "$base/api/tasks/$taskId/apply" $applyBody (AuthHeader $workerToken)
Check "POST /api/tasks/{id}/apply" $r | Out-Null

# ===== 13. 任务详情 =====
$r = Invoke-RestMethod -Uri "$base/api/tasks/$taskId" -Method GET -Headers (AuthHeader $pubToken)
Check "GET /api/tasks/{id}" $r | Out-Null

# ===== 14. 发单人接受申请 =====
$appId = (& $mysqlBin -uroot -p123456 crowdsource -se "SELECT id FROM task_application WHERE task_id=$taskId LIMIT 1;" 2>$null).Trim()
Write-Host "  applicationId=$appId"
$r = Invoke-RestMethod -Uri "$base/api/tasks/applications/$appId/handle?accept=true" -Method POST -Headers (AuthHeader $pubToken)
Check "POST /api/tasks/applications/{id}/handle (接受)" $r | Out-Null

# ===== 15. 推荐任务 =====
$r = Invoke-RestMethod -Uri "$base/api/tasks/recommend" -Method GET -Headers (AuthHeader $workerToken)
Check "GET /api/tasks/recommend" $r | Out-Null

# ===== 16. 通知列表 =====
$r = Invoke-RestMethod -Uri "$base/api/notifications" -Method GET -Headers (AuthHeader $workerToken)
Check "GET /api/notifications (接单人)" $r | Out-Null
Write-Host "  接单人通知数: $($r.data.total)"
$r = Invoke-RestMethod -Uri "$base/api/notifications" -Method GET -Headers (AuthHeader $pubToken)
Check "GET /api/notifications (发单人)" $r | Out-Null

# ===== 17. 未读通知数 =====
$r = Invoke-RestMethod -Uri "$base/api/notifications/unread-count" -Method GET -Headers (AuthHeader $workerToken)
Check "GET /api/notifications/unread-count" $r | Out-Null
Write-Host "  未读数: $($r.data)"

# ===== 18. 标记通知已读 =====
$r = Invoke-RestMethod -Uri "$base/api/notifications/read" -Method PUT -Headers (AuthHeader $workerToken)
Check "PUT /api/notifications/read (全部已读)" $r | Out-Null

# ===== 19. 标记任务完成 =====
$r = Invoke-RestMethod -Uri "$base/api/tasks/$taskId/complete" -Method POST -Headers (AuthHeader $pubToken)
Check "POST /api/tasks/{id}/complete" $r | Out-Null

# ===== 20. 管理员查看用户列表 =====
$r = Invoke-RestMethod -Uri "$base/api/admin/users" -Method GET -Headers (AuthHeader $adminToken)
Check "GET /api/admin/users" $r | Out-Null
Write-Host "  用户总数: $($r.data.total)"

# ===== 21. 管理员下架任务（新发一个）=====
$r = PostJson "$base/api/tasks" '{"title":"测试下架任务","description":"用于测试下架","type":"测试","budgetMin":100,"budgetMax":500}' (AuthHeader $pubToken)
$taskId2 = $r.data
& $mysqlBin -uroot -p123456 crowdsource -e "UPDATE task SET status=2 WHERE id=$taskId2;" 2>$null
$r = Invoke-RestMethod -Uri "$base/api/admin/tasks/$taskId2/offline" -Method POST -Headers (AuthHeader $adminToken)
Check "POST /api/admin/tasks/{id}/offline (下架)" $r | Out-Null

# ===== 22. 管理员禁用用户 =====
$r = Invoke-RestMethod -Uri "$base/api/admin/users/$workerId/status?status=2" -Method PUT -Headers (AuthHeader $adminToken)
Check "PUT /api/admin/users/{id}/status (禁用)" $r | Out-Null

# ===== 23. 无 token 访问受保护接口 =====
try {
    Invoke-RestMethod -Uri "$base/api/user/me" -Method GET | Out-Null
    Write-Host "[FAIL] 无token应返回401" -ForegroundColor Red; $fail++
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 401) {
        Write-Host "[PASS] 无token返回401" -ForegroundColor Green; $pass++
    } else {
        Write-Host "[FAIL] 无token异常: $($_.Exception.Message)" -ForegroundColor Red; $fail++
    }
}

Write-Host ""
Write-Host "============================="
Write-Host "测试结果: PASS=$pass  FAIL=$fail" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Yellow" })
Write-Host "============================="
