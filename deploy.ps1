# ==========================================
# POWER BI REPORT SERVER AUTO-DEPLOY SCRIPT
# ==========================================

# 1. Server aur File ki Details
$ReportServerUrl = "https://analytics.uol.edu.pk/reports"
# 1. Target Folder Dynamic Banana
$TargetFolder = Read-Host "PBIRS ka target folder likhein (Default: /testing)"
if ([string]::IsNullOrWhiteSpace($TargetFolder)) {
    $TargetFolder = "/testing"
}
# Agar user slash lagana bhool jaye toh khud handle kar lein
if (-not $TargetFolder.StartsWith("/")) {
    $TargetFolder = "/$TargetFolder"
}
# User se file ka naam maangna (agar khali chorein toh default use ho)
$PbixFilePath = Read-Host "Deploy karne ke liye .pbix file ka naam likhein (maslan: 'Service Request Dashboard.pbix')"
if ([string]::IsNullOrWhiteSpace($PbixFilePath)) {
    $PbixFilePath = "Service Request Dashboard.pbix"
}

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

        # File ko Base64 encode karna
        $FileBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $PbixFilePath))
        $EncodedFile = [Convert]::ToBase64String($FileBytes)
        
        $FileName = [System.IO.Path]::GetFileNameWithoutExtension($PbixFilePath)
        $ItemPath = "$TargetFolder/$FileName"

        # Credentials Setup
        $Username = "taimoor.hassan1"
        $PasswordText = "T@imoor1?101"
        $SecurePassword = ConvertTo-SecureString $PasswordText -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)

        # 1. Pehle check karein ke kya report server par pehle se mojood hai?
        $CheckUri = "$ReportServerUrl/api/v2.0/CatalogItems?`$filter=Path eq '$ItemPath'"
        $ExistingItem = Invoke-RestMethod -Uri $CheckUri -Method Get -Credential $Credential -ErrorAction SilentlyContinue

        if ($ExistingItem.value.Count -gt 0) {
            Write-Host "Report pehle se mojood hai, purani wali delete ki ja rahi hai..." -ForegroundColor Yellow
            $ExistingId = $ExistingItem.value[0].Id
            $DeleteUri = "$ReportServerUrl/api/v2.0/CatalogItems($ExistingId)"
            Invoke-RestMethod -Uri $DeleteUri -Method Delete -Credential $Credential
        }

        # 2. Nayi report upload karein (Updated OData type)
        $Body = @{
            "@odata.type" = "#Model.PowerBIReport"
            "Name"        = $FileName
            "Path"        = $ItemPath
            "Content"     = $EncodedFile
        } | ConvertTo-Json -Depth 10

        Invoke-RestMethod -Uri $UploadUri -Method Post -Body $Body -ContentType "application/json" -Credential $Credential
        Write-Host "[SUCCESS] Report successfully deployed to Power BI Report Server!" -ForegroundColor Green

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