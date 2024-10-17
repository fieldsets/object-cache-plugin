{
    Import-Module Pode
    Import-Module PsRedis

    # For Connection Strig See: https://stackexchange.github.io/StackExchange.Redis/Configuration
    $params = @{
        Set = {
            param($key, $value, $ttl)
            Import-Module PsRedis

            $redis_host = [System.Environment]::GetEnvironmentVariable('REDIS_HOST')
            $redis_port = [System.Environment]::GetEnvironmentVariable('REDIS_PORT')
            $redis_index = [System.Environment]::GetEnvironmentVariable('OBJECT_CACHE_INDEX')
            $redis_connection_string = "$($redis_host):$($redis_port),defaultDatabase=$($redis_index),ssl=False,abortConnect=False"

            $ttl_timespan = New-TimeSpan -Minutes $ttl

            [ScriptBlock]$script_block = {
                param($k, $v, $t)
                Remove-RedisKey -Key "object-cache:$($k)" | Out-PodeHost
                Add-RedisKey -Key "object-cache:$($k)" -Value $v -TTL $t | Out-PodeHost
            }
            Invoke-RedisScript -ConnectionString "$($redis_connection_string)" -ScriptBlock $script_block -Arguments @($key,$value,$ttl_timespan) | Out-PodeHost
        }
        Get = {
            param($key, $metadata)
            Import-Module PsRedis

            $redis_host = [System.Environment]::GetEnvironmentVariable('REDIS_HOST')
            $redis_port = [System.Environment]::GetEnvironmentVariable('REDIS_PORT')
            $redis_index = [System.Environment]::GetEnvironmentVariable('OBJECT_CACHE_INDEX')
            $redis_connection_string = "$($redis_host):$($redis_port),defaultDatabase=$($redis_index),ssl=False,abortConnect=False"

            "Connection String: $($redis_connection_string)" | Out-PodeHost

            [ScriptBlock]$script_block = {
                param($k)
                return Get-RedisKeyDetails -Key "object-cache:$($k)" -Type 'string'
            }
            $details = Invoke-RedisScript -ConnectionString "$($redis_connection_string)" -ScriptBlock $script_block -Arguments @($key)

            $value = [System.Management.Automation.Internal.StringDecorated]::new($details.Value).ToString('PlainText')
            if ([string]::IsNullOrEmpty($value) -or ($value -ieq '(nil)')) {
                $value = $null
            }

            if ($metadata) {
                $ttl = [int]([System.Management.Automation.Internal.StringDecorated]::new($details.TTL).ToString('PlainText'))

                return @{
                    Key = $key
                    Value = $value
                    Ttl = $ttl
                    Expiry = [datetime]::UtcNow.AddSeconds($ttl)
                    Size = $details.Size
                }
            } else {
                return $value
            }
        }
        Test = {
            param($key)
            Import-Module PsRedis

            $redis_host = [System.Environment]::GetEnvironmentVariable('REDIS_HOST')
            $redis_port = [System.Environment]::GetEnvironmentVariable('REDIS_PORT')
            $redis_index = [System.Environment]::GetEnvironmentVariable('OBJECT_CACHE_INDEX')
            $redis_connection_string = "$($redis_host):$($redis_port),defaultDatabase=$($redis_index),ssl=False,abortConnect=False"

            [ScriptBlock]$script_block = {
                param($k)
                $count = Get-RedisKeysCount -Key "object-cache:$($k)"
                if ([string]::IsNullOrEmpty($count) -or [Int]$count -eq 0) {
                    return $false
                } elseif ([Int]$count -gt 0) {
                    return $true
                } else {
                    return $false
                }
            }
            $exists = Invoke-RedisScript -ConnectionString "$($redis_connection_string)" -ScriptBlock $script_block -Arguments @($key)
            return $exists
        }
        Remove = {
            param($key)
            Import-Module PsRedis

            $redis_host = [System.Environment]::GetEnvironmentVariable('REDIS_HOST')
            $redis_port = [System.Environment]::GetEnvironmentVariable('REDIS_PORT')
            $redis_index = [System.Environment]::GetEnvironmentVariable('OBJECT_CACHE_INDEX')
            $redis_connection_string = "$($redis_host):$($redis_port),defaultDatabase=$($redis_index),ssl=False,abortConnect=False"

            [ScriptBlock]$script_block = {
                param($k)
                Remove-RedisKey -Key "object-cache:$($k)" | Out-PodeHost
            }
            $null = Invoke-RedisScript -ConnectionString "$($redis_connection_string)" -ScriptBlock $script_block -Arguments @($key)
        }
        Clear = {
            Import-Module PsRedis

            $redis_host = [System.Environment]::GetEnvironmentVariable('REDIS_HOST')
            $redis_port = [System.Environment]::GetEnvironmentVariable('REDIS_PORT')
            $redis_index = [System.Environment]::GetEnvironmentVariable('OBJECT_CACHE_INDEX')
            $redis_connection_string = "$($redis_host):$($redis_port),defaultDatabase=$($redis_index),ssl=False,abortConnect=False"

            [ScriptBlock]$script_block = {
                Remove-RedisKeys -Pattern 'object-cache:*' | Out-PodeHost
            }
            $null = Invoke-RedisScript -ConnectionString "$($redis_connection_string)" -ScriptBlock $script_block
        }
    }

    Set-PodeCurrentRunspaceName -Name 'Object-Cache-Redis'
    Write-Information -MessageData 'Setting Default Cache' -InformationAction Continue
    Set-PodeCacheDefaultStorage -Name 'Redis'

    Write-Information -MessageData 'Adding Redis Cache To Pode' -InformationAction Continue
    Add-PodeCacheStorage -Default -Name 'Redis' @params

    Write-Information -MessageData 'Setting Object Cache Endpoint' -InformationAction Continue
    $api_port = [System.Environment]::GetEnvironmentVariable('OBJECT_CACHE_API_PORT')
    Add-PodeEndpoint -Address * -Port "$($api_port)" -Protocol Http -Name 'Object-Cache'

    Write-Information -MessageData 'Adding Routes' -InformationAction Continue

    # Read Requests
    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        Write-PodeTextResponse -Value 'Fieldsets Redis Object Cache Plugin'
    }

    Add-PodeRoute -Method Get -Path '/object-cache/:key' -ScriptBlock {
        $key = $WebEvent.Parameters['key']
        "Fetching Key: $($key)" | Out-PodeHost
        $value = Get-PodeCache -Key "$($key)" -Storage 'Redis' -Metadata
        "Key $($key) has value: $($value)" | Out-PodeHost
        Write-PodeJsonResponse -Value @{
            key = $key
            value = $value
        }
    }

    Add-PodeRoute -Method Post -Path '/object-cache/:key/:value' -ScriptBlock {
        $key = $WebEvent.Parameters['key']
        $value = $WebEvent.Parameters['value']
        Set-PodeCache -Key "$($key)" -InputObject "$($value)" -Ttl 60 -Storage 'Redis'
        Write-PodeJsonResponse -Value @{
            key = $key
            value = $value
        }
    }
}