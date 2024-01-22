# Source: DotJim blog (https://dandraka.com)
# Jim Andrakakis, January 2023
#
 
# ===== Parameters =====
 
param(
    [string]$fileName = 'C:\temp\uploadinfo.json',
    [string]$rqServer = 'http://myServer:15672', # better use HTTPS though
    [string]$rqVhostName = 'myVhost',
    [string]$rqQueueName = 'myQueue',
    [string]$rqExchangeName = 'amq.default', # or your exchange name
    [string]$rqUsername = 'myUser', # this user needs at least 'Management' permissions to post to the REST API
    [string]$rqPassword = 'myPass',
    # RabbitMQ has a recommended message size limit of 128 MB
    # See https://www.cloudamqp.com/blog/what-is-the-message-size-limit-in-rabbitmq.html
    # But of course depending on your app you might want to set it lower
    [int]$rqMessageLimitMB = 128        
)
 
# ======================
 
Clear-Host
$ErrorActionPreference = 'Stop'
$WarningPreference = 'Continue'
 
[string]$rqUrl = "$rqServer/api/exchanges/$rqVhostName/$rqExchangeName/publish"
 
# Sanity check
if (-not (Test-Path $fileName)) {
    Write-Error "File $fileName was not found"
}
 
# Check RabbitMQ size limit
[int]$rqMessageLimit = $rqMessageLimitMB * 1024 * 1024 
[long]$fileSize = (Get-Item -Path $fileName).Length
if ($fileSize -gt $rqMessageLimit) {
    Write-Error "File $fileName is bigger that the maximum size allowed by RabbitMQ ($rqMessageLimitMB MB)"
}
 
$plainCredentials = "$($rqUsername):$($rqPassword)"
$encodedCredentials = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($plainCredentials))
$authHeader = "Basic " + $encodedCredentials
 
[string]$content = Get-Content -Path $fileName -Encoding UTF8
$msgBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
$json = "{`"properties`":{`"content_type`":`"application/json`",`"delivery_mode`":2},`"routing_key`":`"$rqQueueName`",`"payload`":`"$msgBase64`",`"payload_encoding`":`"base64`"}"
$resp = Invoke-WebRequest -Method Post -Uri $rqUrl -Headers @{'Authorization'= $authHeader} -Body $json
if([math]::Floor($resp.StatusCode/100) -ne 2) {
    Write-Error "File $fileName could not be posted, error $($resp.BaseResponse)"
}
 
Write-Host "File $fileName was posted to $rqUrl"
