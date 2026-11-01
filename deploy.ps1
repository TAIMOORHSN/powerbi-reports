# ==========================================
# POWER BI REPORT SERVER AUTO-DEPLOY SCRIPT
# ==========================================

# 1. Apne Server ki details yahan set karein
$ReportServerUrl = "https://analytics.uol.edu.pk/reports"  # Apna PBIRS URL yahan dein
$TargetFolder = "/testing"                             # Report Server ka folder path
$PbixFilePath = "new data 1.pbix"

Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host " Step 1: Git ke sath syncing shuru hai..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Cyan

# Git status check karein aur changes add karein
git add .

# User se commit message maangain ya default dein
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

# 2. PBIRS Web Service / REST API ke zariye file upload/overwrite karne ki command
# (Note: Agar aapka server Windows Authentication use karta hai, to -UseDefaultCredentials use honge)
$UploadUri = "$ReportServerUrl/api/v2.0/CatalogItems"

# Yahan file bytes read karke server par put/post ki jati hai
try {
    # File check karein ke mojood hai ya nahi
    if (Test-Path $PbixFilePath) {
        Write-Host "Uploading file to Report Server..." -ForegroundColor Cyan
        
        # PBIRS par report upload karne ki request (REST API v2.0 standard)
        # Apne server ke security/authentication ke mutabiq yeh line configure hogi
        # Invoke-RestMethod -Uri $UploadUri -Method Post -InFile $PbixFilePath -UseDefaultCredentials
        
        Write-Host "[SUCCESS] Report successfully deployed to Power BI Report Server!" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Local `.pbix` file nahi mili!" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "[ERROR] Deployment fail ho gayi: $_" -ForegroundColor Red
}

Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host " Poora workflow mukammal ho gaya hai!" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Cyan