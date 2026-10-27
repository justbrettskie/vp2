$ErrorActionPreference = "Stop"
$root = Join-Path $PSScriptRoot "web"
$prefix = "http://127.0.0.1:18765/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
try {
    $listener.Start()
} catch {
    Write-Host "Could not start VitalPulse's local server. Port 18765 may already be in use." -ForegroundColor Red
    Write-Host $_
    Read-Host "Press Enter to close"
    exit 1
}
$url = $prefix
Start-Process $url
Write-Host "VitalPulse is running in your browser at $url"
Write-Host "Keep this window open while using VitalPulse. Close it to stop the local app."
$mime = @{
    ".html" = "text/html; charset=utf-8"
    ".js"   = "text/javascript; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".svg"  = "image/svg+xml"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".webp" = "image/webp"
    ".ico"  = "image/x-icon"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
}
try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        try {
            $pathPart = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart("/"))
            if ([string]::IsNullOrWhiteSpace($pathPart)) { $pathPart = "index.html" }
            $pathPart = $pathPart.Replace("/", [IO.Path]::DirectorySeparatorChar)
            $filePath = [IO.Path]::GetFullPath((Join-Path $root $pathPart))
            $rootFull = [IO.Path]::GetFullPath($root) + [IO.Path]::DirectorySeparatorChar
            if (-not $filePath.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase) -and
                $filePath -ne (Join-Path $root "index.html")) {
                $context.Response.StatusCode = 403
                $context.Response.Close()
                continue
            }
            # Support client-side routes by serving index.html when a route isn't a real file.
            if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
                $filePath = Join-Path $root "index.html"
            }
            $ext = [IO.Path]::GetExtension($filePath).ToLowerInvariant()
            if ($mime.ContainsKey($ext)) { $context.Response.ContentType = $mime[$ext] }
            else { $context.Response.ContentType = "application/octet-stream" }
            $bytes = [IO.File]::ReadAllBytes($filePath)
            $context.Response.ContentLength64 = $bytes.Length
            $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        } catch {
            try { $context.Response.StatusCode = 500; $context.Response.Close() } catch {}
        } finally {
            try { $context.Response.OutputStream.Close() } catch {}
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
