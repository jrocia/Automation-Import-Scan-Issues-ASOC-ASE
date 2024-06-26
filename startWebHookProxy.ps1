# Copyright 2023 HCL America
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###################################################################
# Update the variables on this block
$asocApiKeyId='aaaaaaaaaaaaaaaaaaaaaaaaa'
$asocApiKeySecret='aaaaaaaaaaaaaaaaaaaaaaaaa'
$presenceId='aaaaaaaaaaaaaaaaaaaaaaaaa'
$aseHostname='aaaaaaaaaaaaaaaaaaaaaaaaa'
$aseApiKeyId='aaaaaaaaaaaaaaaaaaaaaaaaa'
$aseApiKeySecret='aaaaaaaaaaaaaaaaaaaaaaaaa'
###################################################################

# Updating importScanResults.ps1 file
$importScriptContent=Get-Content .\importScanResults.ps1
$importScriptContent -replace "aseHostname='(.*)'" , "aseHostname='$aseHostname'" -replace "aseApiKeyId='(.*)'" , "aseApiKeyId='$aseApiKeyId'" -replace "aseApiKeySecret='(.*)'" , "aseApiKeySecret='$aseApiKeySecret'" | Out-File .\importScanResults.ps1

# Updating config.json file
$jsonConfig = Get-Content .\config.json | ConvertFrom-Json 
$jsonConfig.asoc_api_key.KeyId = $asocApiKeyId
$jsonConfig.asoc_api_key.KeySecret = $asocApiKeySecret
$jsonConfig.webhooks.asoc[0].PresenceId = $presenceId
$jsonConfig | ConvertTo-Json -Depth 10 | Out-File .\config.json 

# Downloading AppScan Presence
$asocToken=$(Invoke-WebRequest -Method "POST" -Headers @{"Accept"="application/json"} -ContentType 'application/json' -Body "{`"keyId`": `"$asocApiKeyId`",`"keySecret`": `"$asocApiKeySecret`"}" -Uri 'https://cloud.appscan.com/api/v4/Account/ApiKeyLogin' -SkipCertificateCheck | Select-Object -Expand Content | ConvertFrom-Json | select -ExpandProperty Token);
Remove-Item *AppScanPresence* -Force -Recurse
Invoke-WebRequest -Method "GET" -Headers @{"Accept"="application/json";"Authorization"="Bearer $asocToken"} https://cloud.appscan.com/api/v4/Presences/$presenceId/Download/win_x64 -outfile AppScanPresence.zip
Expand-Archive .\AppScanPresence.zip
Start-Process .\AppScanPresence\Presence.exe -PassThru -NoNewWindow

# Running Asoc Web Hook Proxy (Python Flask). Interface 127.0.0.1 port 5000
do{
	$env:FLASK_ENV='development'
	$env:FLASK_APP='asoc_webhook_proxy'
	$proc = Start-Process py -ArgumentList ' -m flask run --host=127.0.0.1 --port=5000 --no-reload' -PassThru -NoNewWindow
	Start-Sleep -seconds 3600
	$proc | Stop-Process
}while ($true)
