Configuration InstallIIS
# Configuration Main
{
    Param (
        [string] $nodeName = "localhost",
        [string] $assemblyBlobPath = "https://jpda.blob.core.windows.net/shared/Microsoft.Web.Iis.Rewrite.Providers.dll?st=2017-03-30T19%3A17%3A00Z&se=2018-03-31T19%3A17%3A00Z&sp=r&sv=2015-12-11&sr=b&sig=%2BwJWk8%2FgCnDs4LRW6pxDDl5Cde7ZeilmlROlITGMwcY%3D",
        [string] $fileMapPath = "https://jpda.blob.core.windows.net/shared/filemap.txt",
        [string] $localAssemblyPath = "c:\app\",
        [string] $targetAssemblyName = "Microsoft.Web.Iis.Rewrite.Providers",
        [string] $rewriteProviderName = "FileMapProviderSample",
        [string] $rewriteProviderType = "FileMapProvider, Microsoft.Web.Iis.Rewrite.Providers, Version=7.1.761.0, Culture=neutral, PublicKeyToken=0545b0627da60a5f",
        [string] $rewriteProviderFile = "https://jpda.blob.core.windows.net/shared/pathmap.txt?st=2017-04-03T17%3A15%3A00Z&se=2018-04-04T17%3A15%3A00Z&sp=r&sv=2015-12-11&sr=c&sig=2dNROSd8OkY53Ogx09dR%2Bro6dxNIxqJGerF8sZdicXc%3D"
    )
    # no variables here? this seems lame
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Node $nodeName
    {
        WindowsFeature WebServerRole {
            Name = "Web-Server"
            Ensure = "Present"
        }
        WindowsFeature WebManagementConsole {
            Name = "Web-Mgmt-Console"
            Ensure = "Present"
        }
        WindowsFeature WebManagementService {
            Name = "Web-Mgmt-Service"
            Ensure = "Present"
        }
        WindowsFeature ASPNet45 {
            Name = "Web-Asp-Net45"
            Ensure = "Present"
        }
        WindowsFeature HTTPRedirection {
            Name = "Web-Http-Redirect"
            Ensure = "Present"
        }
        WindowsFeature CustomLogging {
            Name = "Web-Custom-Logging"
            Ensure = "Present"
        }
        WindowsFeature LoggingTools {
            Name = "Web-Log-Libraries"
            Ensure = "Present"
        }
        WindowsFeature RequestMonitor {
            Name = "Web-Request-Monitor"
            Ensure = "Present"
        }
        WindowsFeature Tracing {
            Name = "Web-Http-Tracing"
            Ensure = "Present"
        }
        WindowsFeature BasicAuthentication {
            Name = "Web-Basic-Auth"
            Ensure = "Present"
        }
        WindowsFeature WindowsAuthentication {
            Name = "Web-Windows-Auth"
            Ensure = "Present"
        }
        WindowsFeature ApplicationInitialization {
            Name = "Web-AppInit"
            Ensure = "Present"
        }
        Package UrlRewrite {
            DependsOn = "[WindowsFeature]WebServerRole"
            Ensure = "Present"
            Name = "IIS URL Rewrite Module 2"
            Path = "http://download.microsoft.com/download/C/9/E/C9E8180D-4E51-40A6-A9BF-776990D8BCA9/rewrite_amd64.msi"
            Arguments = "/quiet"
            ProductId = "08F0318A-D113-4CF0-993E-50F191D397AD"
            #ProductId = "E138811C-C09D-4E20-97BC-256BB06D2C66"
        }
        Script DownloadRewriteAssemblyFromBlobStorage {
            GetScript = {
                $assemblyBlobUri = new-object System.Uri($assemblyBlobPath)
                $fileName = [System.IO.Path]::GetFileName($assemblyBlobUri.LocalPath)
                return Test-Path ([System.IO.Path]::Combine($using:localAssemblyPath, $using:fileName))
            }
            TestScript = {
                $assemblyBlobUri = new-object System.Uri($using:assemblyBlobPath)
                $fileName = [System.IO.Path]::GetFileName($assemblyBlobUri.LocalPath)
                return Test-Path ([System.IO.Path]::Combine($using:localAssemblyPath, $using:fileName))
            }
            SetScript = {
                $assemblyBlobUri = new-object System.Uri($using:assemblyBlobPath)
                $fileName = [System.IO.Path]::GetFileName($assemblyBlobUri.LocalPath)
                New-Item -ItemType Directory $using:localAssemblyPath -Force
                Invoke-WebRequest -Uri $using:assemblyBlobPath -OutFile ([System.IO.Path]::Combine($using:localAssemblyPath, $fileName))
            }
        }
        Script InstallRewriteAssemblyToGac {
            GetScript = {
                $gacAssembly = [Reflection.Assembly]::LoadWithPartialName($using:targetAssemblyName)
                return $gacAssembly.Length -gt 0
            }
            TestScript = {
                #potentially just return false here - will force a re-gac each time. useful for updates. can also inspect the version that's returned in LoadWithPartialName
                $gacAssembly = [Reflection.Assembly]::LoadWithPartialName($using:targetAssemblyName)
                return $gacAssembly.Length -gt 0
            }
            SetScript = {
                $assemblyBlobUri = new-object System.Uri($using:assemblyBlobPath)
                $fileName = [System.IO.Path]::GetFileName($assemblyBlobUri.LocalPath)
                $path = [System.IO.Path]::Combine($using:localAssemblyPath, $fileName)
                [System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, PublicKeyToken=b03f5f7f11d50a3a")
                (New-Object System.EnterpriseServices.Internal.Publish).GacInstall($path)
            }
        }
        Script AddCustomRewriteProviderToIIS {
            DependsOn = "[Package]UrlRewrite", "[Script]InstallRewriteAssemblyToGac"
            GetScript = {
                return Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/rewrite/providers" -name "." | select -ExpandProperty collection | Where-Object { $_.name -eq $using:rewriteProviderName}
            }
            TestScript = {
                $configBlock = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/rewrite/providers" -name "." | select -ExpandProperty collection | Where-Object { $_.name -eq $using:rewriteProviderName}
                return $configBlock.Length -gt 0
            }
            SetScript = {
                # Remove-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/rewrite/providers" -name "." -AtElement @{name = $using:rewriteProviderName}
                Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/rewrite/providers" -name "." -value @{name = $using:rewriteProviderName; type = $using:rewriteProviderType}
            }
        }
        Script ConfigureRewriteProvider {
            DependsOn = "[Package]UrlRewrite", "[Script]InstallRewriteAssemblyToGac", "[Script]AddCustomRewriteProviderToIIS"
            GetScript = {
                return Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/providers" -name "." | Select-Object -ExpandProperty collection | Where-Object { $_.name -eq $using:rewriteProviderName}
            }
            TestScript = {
                $rewriteProviderFileUri = new-object System.Uri($using:rewriteProviderFile)
                $fileName = [System.IO.Path]::GetFileName($rewriteProviderFileUri.LocalPath)
                $localFilePath = [System.IO.Path]::Combine($using:localAssemblyPath, $fileName)
                $fileExists = Test-Path($localFilePath)
                if (!$fileExists) { return $false; }

                $properties = @{"FilePath" = $localFilePath; "IgnoreCase" = 1; "Separator" = ","}

                $provider = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/rewrite/providers" -name "." | Select-Object -ExpandProperty collection | Where-Object { $_.name -eq $using:rewriteProviderName}
                Write-Verbose "Getting provider with name $using:rewriteProviderName..."
                if ($provider -eq $null) { return $false; }
                
                Write-Verbose "Found $($provider.name), checking configuration..."
                # Write-Verbose "found $($provider | select-object -ExpandProperty settings | out-string) ok"
                foreach ($key in $properties.keys) {
                    Write-Verbose "Checking for key $key..."
                    $prop = $provider | Select-Object -ExpandProperty settings | Select-Object -ExpandProperty collection | Where-Object { $_.key -eq $key }
                    if ($prop -eq $null) {
                        Write-Verbose "$key doesn't exist! Exiting..."
                        return $false; 
                    }
                    Write-Verbose "Found $($prop.value) in configuration. Desired value for $key is $($properties[$key])"
                    if ($prop.value -ne $properties[$key]) { 
                        Write-Verbose "$key values don't match"
                        return $false; 
                    }
                }
                Write-Verbose "Configuration all good, no need to reapply"
                return $true;
            }
            SetScript = {
                # download settings file
                $rewriteProviderFileUri = new-object System.Uri($using:rewriteProviderFile)
                $fileName = [System.IO.Path]::GetFileName($rewriteProviderFileUri.LocalPath)
                $localFile = [System.IO.Path]::Combine($using:localAssemblyPath, $fileName)
                New-Item -ItemType Directory $using:localAssemblyPath -Force
                Invoke-WebRequest -Uri $rewriteProviderFileUri -OutFile $localFile
                
                Write-Verbose "Saved config file to $localFile, now configuring IIS: $using:rewriteProviderName..."
                
                # set IIS configuration settings for the specific provider
                $properties = @{"FilePath" = $localFile; "IgnoreCase" = 1; "Separator" = ","}

                #Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/rewrite/providers/provider[@name='$($using:rewriteProviderName)']/settings" -name "." -value @{key='FilePath';value='c:\app\stuff.txt'}
                #Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/rewrite/providers/provider[@name='$($using:rewriteProviderName)']/settings" -name "." -value @{key='Separator';value=','}
                #Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/rewrite/providers/provider[@name='$($using:rewriteProviderName)']/settings" -name "." -value @{key='IgnoreCase';value='1'}

                foreach($key in $properties.keys){
                    Write-Verbose "Removing configuration if exists..."
                    Remove-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/rewrite/providers/provider[@name='$($using:rewriteProviderName)']/settings" -name "." -AtElement @{key=$($key)}
                    Write-Verbose "Adding config for $($key) with $($properties[$key])"
                    Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/rewrite/providers/provider[@name='$($using:rewriteProviderName)']/settings" -name "." -value @{key = $($key); value = $($properties[$key])} -Verbose
                }
            }
        }
        #<rule name="FileMapProviderTest" stopProcessing="true">
        #<match url="(.*)" />
        #<conditions>
        #    <add input="{FileMap:{R:1}}" pattern="(.+)" />
        #</conditions>
        #<action type="Redirect" url="{C:1}" />
        #</rule>
        Script ReWriteRules {
            DependsOn = "[Package]UrlRewrite", "[Script]AddCustomRewriteProviderToIIS", "[Script]InstallRewriteAssemblyToGac", "[Script]ConfigureRewriteProvider"
            SetScript = {
                $current = Get-WebConfiguration /system.webServer/rewrite/allowedServerVariables | select -ExpandProperty collection | ? {$_.ElementTagName -eq "add"} | select -ExpandProperty name
                $expected = @("HTTPS", "HTTP_X_FORWARDED_FOR", "HTTP_X_FORWARDED_PROTO", "REMOTE_ADDR")
                $missing = $expected | where {$current -notcontains $_}
                try {
                    Start-WebCommitDelay 
                    $missing | % { Add-WebConfiguration /system.webServer/rewrite/allowedServerVariables -atIndex 0 -value @{name = "$_"} -Verbose }
                    Stop-WebCommitDelay -Commit $true 
                } 
                catch [System.Exception] { 
                    $_ | Out-String
                }
            }
            TestScript = {
                $current = Get-WebConfiguration /system.webServer/rewrite/allowedServerVariables | select -ExpandProperty collection | select -ExpandProperty name
                $expected = @("HTTPS", "HTTP_X_FORWARDED_FOR", "HTTP_X_FORWARDED_PROTO", "REMOTE_ADDR")
                $result = -not @($expected| where {$current -notcontains $_}| select -first 1).Count
                return $result
            }
            GetScript = {
                $allowedServerVariables = Get-WebConfiguration /system.webServer/rewrite/allowedServerVariables | select -ExpandProperty collection
                return $allowedServerVariables
            }
        }
    }
}

InstallIIS