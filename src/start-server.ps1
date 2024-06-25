{
    Import-Module Pode
    Import-Module PsRedis
    $redis_host = [System.Environment]::GetEnvironmentVariable('REDIS_HOST')
    $redis_port = [System.Environment]::GetEnvironmentVariable('REDIS_PORT')
    $redis_index = [System.Environment]::GetEnvironmentVariable('OBJECT_CACHE_INDEX')

    # For Connection Strig See: https://stackexchange.github.io/StackExchange.Redis/Configuration
    $params = @{
        Name = 'Redis'
        Set = {
            param($key, $value, $ttl)
            Import-Module PsRedis
            $script_block = {
                param($k, $v, $t)
                Remove-RedisKey -Key $k | Out-Null
                Add-RedisKey -Key $k -Value $v -TTL $t
            }
            $null = Invoke-RedisScript -ConnectionString "$($redis_host):$($redis_port),defaultDatabase=$($redis_index),ssl=False,abortConnect=False" -ScriptBlock $script_block -Arguments @($key,$value,$ttl)
        }
        Get = {
            param($key, $metadata)
            Import-Module PsRedis
            $script_block = {
                param($k)
                return Get-RedisKeyDetails -Key $k -Type 'string'
            }
            $details = Invoke-RedisScript -ConnectionString "$($redis_host):$($redis_port),defaultDatabase=$($redis_index),ssl=False,abortConnect=False" -ScriptBlock $script_block -Arguments @($key)

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
            $script_block = {
                param($k)
                $ttl = Get-RedisKeyTTL -Key $k
                if ([Int]$ttl -eq -2) {
                    return $false
                }
                return $true
            }
            $exists = Invoke-RedisScript -ConnectionString "$($redis_host):$($redis_port),defaultDatabase=$($redis_index),ssl=False,abortConnect=False" -ScriptBlock $script_block -Arguments @($key)
            return $exists
        }
        Remove = {
            param($key)
            Import-Module PsRedis
            $script_block = {
                param($k)
                Remove-RedisKey -Key $k | Out-Null
            }
            $null = Invoke-RedisScript -ConnectionString "$($redis_host):$($redis_port),defaultDatabase=$($redis_index),ssl=False,abortConnect=False" -ScriptBlock $script_block -Arguments @($key)
        }
        Clear = {}
    }

    Write-Information -MessageData 'Adding Redis Cache To Pode' -InformationAction Continue
    Add-PodeCacheStorage @params

    Write-Information -MessageData 'Setting Default Cache' -InformationAction Continue
    Set-PodeCacheDefaultStorage -Name 'Redis'

    Write-Information -MessageData 'Setting Object Cache Endpoint' -InformationAction Continue
    Add-PodeEndpoint -Address * -Port 8080 -Protocol Http -Name 'ObjectCache'

    Write-Information -MessageData 'Adding Routes' -InformationAction Continue
    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        Write-PodeTextResponse -Value 'Some Message'
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

    Add-PodeRoute -Method Get -Path '/object-cache/:key' -ScriptBlock {
        $key = $WebEvent.Parameters['key']
        $value = Get-PodeCache -Key "$($key)" -Storage 'Redis'
        Write-PodeJsonResponse -Value @{
            key = $key
            value = $value
        }
    }
}