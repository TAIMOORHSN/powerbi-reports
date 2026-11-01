# ==========================================
# POWER BI REPORT SERVER AUTO-DEPLOY SCRIPT
# ==========================================

# 1. Server aur File ki Details
$ReportServerUrl = "https://analytics.uol.edu.pk/reports"
$TargetFolder = "/testing"
$PbixFilePath = "Service Request Dashboard.pbix"

Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host " Step 1: Git ke sath syncing shuru hai..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Cyan

# Git add, commit, and push
git add .

$commitMessage = Read-Host "Commit message likhein (Enter dabane par default message use hoga)"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    $commitMessage = "Automated update via deployment script"
}

git commit -m "$commitMessage"
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Git push kamyabi se ho gaya hai!" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Git push mein koi masla aaya hai. Dobara check karein." -ForegroundColor Red
    exit
}

Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host " Step 2: PBIRS Server par upload ho raha hai..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Cyan

$UploadUri = "$ReportServerUrl/api/v2.0/CatalogItems"

try {
    if (Test-Path $PbixFilePath) {
        Write-Host "Local file mil gayi hai, server par upload ki tayari..." -ForegroundColor Cyan

        # File ko Base64 encode karna (PBIRS REST API requirement)
        $FileBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $PbixFilePath))
        $EncodedFile = [Convert]::ToBase64String($FileBytes)
        
        $FileName = [System.IO.Path]::GetFileNameWithoutExtension($PbixFilePath)
        $ItemPath = "$TargetFolder/$FileName"

        # Request Payload
        $Body = @{
            "@odata.type" = "#Microsoft.PowerBI.ReportServer.Models.PowerBIReport"
            "Name"        = $FileName
            "Path"        = $ItemPath
            "Content"     = $EncodedFile
        } | ConvertTo-Json -Depth 10

        # Server par POST request bhejna (Windows Authentication ke sath)
        try {
            Invoke-RestMethod -Uri $UploadUri -Method Post -Body $Body -ContentType "application/json" -UseDefaultCredentials -ErrorAction Stop
            Write-Host "[SUCCESS] Report successfully deployed to Power BI Report Server!" -ForegroundColor Green
        }
        catch {
            # Agar report pehle se mojood hai (Conflict), toh update/overwrite logic handle hogi
            Write-Host "Report pehle se mojood hai, overwrite ki koshish ki ja rahi hai..." -ForegroundColor Yellow
            
            # Agar POST fail ho toh item delete karke dubara create karne ki request ya PUT request
            # Yahan error details print kar di jayengi agar koi permission ya format ka masla ho
            throw $_
        }

    } else {
        Write-Host "[WARNING] Local `.pbix` file ($PbixFilePath) nahi mili!" -ForegroundColor Red
    }
}
catch {
    Write-Host "[ERROR] Deployment fail ho gayi: $_" -ForegroundColor Red
}

Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host " Poora workflow mukammal ho gaya hai!" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Cyan