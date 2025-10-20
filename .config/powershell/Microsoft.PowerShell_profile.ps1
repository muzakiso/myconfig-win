# 提示符配置
function prompt {
    # 第一行：路径信息（蓝色），家目录用 ~ 代替
    $currentPath = $PWD.Path
    if ($currentPath -like "$HOME*") {
        $currentPath = $currentPath -replace [regex]::Escape($HOME), "~"
    }
    
    # Git 信息
    $gitInfo = ""
    $gitBranch = git branch --show-current 2>$null
    if ($gitBranch) {
        $gitStatus = git status --porcelain 2>$null
        
        # 使用 ANSI 转义序列设置不同颜色
        if ($gitStatus) {
            $statusSymbol = "`e[91m!`e[0m"  # 91m = 亮红色
        } else {
            $statusSymbol = "`e[92m✓`e[0m"  # 92m = 亮绿色
        }
        
        # 分别输出不同颜色的部分
        Write-Host "$currentPath" -ForegroundColor Blue -NoNewline
        Write-Host " on " -ForegroundColor Magenta -NoNewline
        Write-Host " $gitBranch" -ForegroundColor Magenta -NoNewline
        Write-Host " [" -ForegroundColor White -NoNewline
        Write-Host $statusSymbol -NoNewline
        Write-Host "]" -ForegroundColor White
    } else {
        # 没有Git信息时只显示路径
        Write-Host "$currentPath" -ForegroundColor Blue
    }
    
    # 第二行：绿色箭头
    Write-Host "❯" -NoNewline -ForegroundColor Green
    
    return " "
}

# 一些别名
function .. { Set-Location .. }
Set-Alias -Name ls -Value eza
function ll { eza -lh --git --icons $args }
function la { eza -lha --git --icons $args }
function lt { eza -T --icons $args }
function scoop {
    $command = $args[0]
    $remainingArgs = $args[1..($args.Length)]
    
    if ($command -eq "search") {
        scoop-search @remainingArgs
    } else {
        # 使用scoop.cmd确保调用正确的可执行文件
        scoop.cmd @args
    }
}
function vi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
        [string[]]$Paths
    )
    
    if ($Paths) {
        # 处理多个文件参数
        $allPaths = $Paths | ForEach-Object { 
            if ($_ -match ' ') {
                "`"$_`""
            } else {
                $_
            }
        }
        $arguments = @("--frame", "none") + $allPaths
        Start-Process -FilePath "neovide" -ArgumentList $arguments -NoNewWindow
    } else {
        Start-Process -FilePath "neovide" -ArgumentList @("--frame", "none") -NoNewWindow
    }
}
#配置yazi
function y {
    $tmp = (New-TemporaryFile).FullName
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }
    Remove-Item -Path $tmp
}

# 引入 PSCompletions 模块，用于动态补全
Import-Module PSCompletions

# 快捷键设置
Set-PSReadLineKeyHandler -Key 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Key 'Ctrl+d' -Function DeleteCharOrExit
Set-PSReadLineKeyHandler -Key 'Ctrl+a' -Function BeginningOfLine
Set-PSReadLineKeyHandler -Key 'Ctrl+e' -Function EndOfLine
Set-PSReadLineKeyHandler -Key 'Ctrl+u' -Function BackwardDeleteLine
Set-PSReadLineKeyHandler -Key 'Ctrl+k' -Function ForwardDeleteLine
Set-PSReadLineKeyHandler -Key 'Ctrl+Shift+a' -Function SelectAll

# 设置默认编码（解决中文乱码）
$OutputEncoding = [System.Text.Encoding]::UTF8

# PSReadLine 配置
$params = @{
    HistoryNoDuplicates = $true
    ShowToolTips = $true
    BellStyle = 'None'
    HistorySearchCursorMovesToEnd = $true
}

if ($PSEdition -eq 'Core') {
    $params.Add('PredictionSource', 'HistoryAndPlugin')
    $params.Add('PredictionViewStyle', 'ListView')
}

Set-PSReadLineOption @params

# zoxide配置
# 设置环境变量（必须在初始化之前）
$env:_ZO_ECHO = "1"  # 跳转时显示路径
$env:_ZO_EXCLUDE_DIRS = "$HOME\Downloads;$HOME\AppData\Local\Temp"  # 排除临时目录
$env:_ZO_FZF_OPTS = "--height 40% --layout=reverse --border"  # 美化 fzf
$env:_ZO_MAXAGE = "2000"  # 限制数据库大小

Invoke-Expression (& { (zoxide init powershell | Out-String) })

# 配置代理
function px {
    param(
        [string]$Command = "status"
    )

    $proxyUrl = "http://127.0.0.1:7897/"
    
    switch ($Command.ToLower()) {
        "on" {
            $env:HTTP_PROXY = $proxyUrl
            $env:HTTPS_PROXY = $proxyUrl
            $env:ALL_PROXY = $proxyUrl
            
            # 设置 PowerShell 的默认代理（可选）
            [System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy($proxyUrl)
            [System.Net.WebRequest]::DefaultWebProxy.BypassProxyOnLocal = $true
            
            Write-Host "✅ 代理已开启: $proxyUrl" -ForegroundColor Green
            Write-Host "   HTTP_PROXY: $env:HTTP_PROXY"
            Write-Host "   HTTPS_PROXY: $env:HTTPS_PROXY"
        }
        
        "off" {
            $env:HTTP_PROXY = $null
            $env:HTTPS_PROXY = $null
            $env:ALL_PROXY = $null
            
            # 清除 PowerShell 的默认代理设置
            [System.Net.WebRequest]::DefaultWebProxy = $null
            
            Write-Host "❌ 代理已关闭" -ForegroundColor Yellow
        }
        
        "status" {
            Write-Host "=== 代理状态 ===" -ForegroundColor Cyan
            if ($env:HTTP_PROXY) {
                Write-Host "✅ HTTP 代理: $env:HTTP_PROXY" -ForegroundColor Green
            } else {
                Write-Host "❌ HTTP 代理: 未设置" -ForegroundColor Red
            }
            
            if ($env:HTTPS_PROXY) {
                Write-Host "✅ HTTPS 代理: $env:HTTPS_PROXY" -ForegroundColor Green
            } else {
                Write-Host "❌ HTTPS 代理: 未设置" -ForegroundColor Red
            }
            
            if ($env:ALL_PROXY) {
                Write-Host "✅ ALL_PROXY: $env:ALL_PROXY" -ForegroundColor Green
            } else {
                Write-Host "❌ ALL_PROXY: 未设置" -ForegroundColor Red
            }
        }
        
        "help" {
            Write-Host "=== 代理管理帮助 ===" -ForegroundColor Cyan
            Write-Host "px on      - 开启代理"
            Write-Host "px off     - 关闭代理" 
            Write-Host "px status  - 查看代理状态"
            Write-Host "px help    - 显示此帮助信息"
            Write-Host ""
            Write-Host "当前代理地址: $proxyUrl"
        }
        
        default {
            Write-Host "❓ 未知命令: $Command" -ForegroundColor Red
            Write-Host "使用 'px help' 查看可用命令"
        }
    }
}

# 配置starship
#Invoke-Expression (&starship init powershell)
