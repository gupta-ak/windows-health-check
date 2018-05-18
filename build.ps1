 param (
    [Parameter(Mandatory=$true)][string]$dockerhubRepo
 )

$ErrorActionPreference = "Stop"

$ctxDir="img"

Expand-Archive -DestinationPath . -Force "$ctxDir.zip"
cp Dockerfile $ctxDir
cp Dockerfile.1709 $ctxDir

$windowsVersions = @("1709", "1803")
$images = @()

foreach ($winver in $windowsVersions)
{
    # Need a special docker file for 1709 to copy curl binary.
    $dockerfileName = if ($winver -eq "1709") { "$ctxDir/Dockerfile.1709" } else { "$ctxDir/Dockerfile" }

    $imageName = "${dockerhubRepo}:$winver"

    # Build the image
    docker build --pull --build-arg VERSION=$winver --isolation=hyperv -t $imageName -f $dockerfileName img
    if ($LASTEXITCODE -ne 0)
    {
        Write-Error "Failed to build $imageName"
    }

    # Verify that the image runs
    docker run --entrypoint=cmd --rm --isolation=hyperv $imageName /c echo running image $imageName  
    if ($LASTEXITCODE -ne 0)
    {
        Write-Error "Failed to run $imageName"
    }

    # Push to docker hub
    docker push $imageName
    if ($LASTEXITCODE -ne 0)
    {
        Write-Error "Failed to push $imageName"
    }

    $images += $imageName
}

# Create manifest list
$manifestList = "docker.io/${dockerhubRepo}:latest"
docker manifest create  $manifestList @images
if ($LASTEXITCODE -ne 0)
{
    Write-Error "Failed to create manifest list $manifestList"
}

# Upload manifest
docker manifest push -p $manifestList
if ($LASTEXITCODE -ne 0)
{
    Write-Error "Failed to push manifest list $manifestList"
}