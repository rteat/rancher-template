# Prompts for Cluster Name and runs Helm template for Rancher K3s vSphere cluster.
# Usage: .\install-prompt.ps1 [--apply]
#   --apply  Pipe output to kubectl apply (default: print manifests only)

param(
    [switch]$Apply
)

$clusterName = Read-Host "Enter Cluster Name"
if ([string]::IsNullOrWhiteSpace($clusterName)) {
    Write-Error "Cluster Name is required."
    exit 1
}

$setArgs = @(
    "template", "rancher-k3s", ".",
    "--set", "clusterName=$clusterName"
)

Write-Host "Rendering Helm chart with clusterName=$clusterName ..." -ForegroundColor Cyan
if ($Apply) {
    helm @setArgs | kubectl apply -f -
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Manifests applied. Check Rancher UI: Cluster Management > $clusterName" -ForegroundColor Green
    }
} else {
    helm @setArgs
    Write-Host "`nTo apply to the Rancher management cluster, run:" -ForegroundColor Yellow
    Write-Host "  helm template rancher-k3s . --set clusterName=$clusterName | kubectl apply -f -" -ForegroundColor White
}
