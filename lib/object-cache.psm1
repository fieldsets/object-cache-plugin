<#
.Synopsis
Get a cache value by key
#>
function cacheGet {
    Param(
        [Parameter(Mandatory=$true,Position=0)][String]$key
    )

    $response = Invoke-RestMethod -Uri "http://localhost:8080/object-cache/$($key)" -Method 'Get'

    return $response
}
Export-ModuleMember -Function cacheGet


function cacheSet {
    Param(
        [Parameter(Mandatory=$true,Position=0)][String]$key,
        [Parameter(Mandatory=$true,Position=1)][String]$value
    )
    $response = Invoke-RestMethod -Uri "http://localhost:8080/object-cache/$($key)/$($value)" -Method 'Post'

    return $response
}
Export-ModuleMember -Function cacheSet