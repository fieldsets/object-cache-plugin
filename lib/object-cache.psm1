<#
.Synopsis
Get a cache value by key
#>
function objectCacheGet {
    Param(
        [Parameter(Mandatory=$true,Position=0)][String]$key
    )

    $response = Invoke-RestMethod -Uri "http://localhost:8080/object-cache/$($key)" -Method 'Get'

    return $response
}
Export-ModuleMember -Function objectCacheGet


function objectCacheSet {
    Param(
        [Parameter(Mandatory=$true,Position=0)][String]$key,
        [Parameter(Mandatory=$true,Position=1)][String]$value
    )
    $response = Invoke-RestMethod -Uri "http://localhost:8080/object-cache/$($key)/$($value)" -Method 'Post'

    return $response
}
Export-ModuleMember -Function objectCacheSet