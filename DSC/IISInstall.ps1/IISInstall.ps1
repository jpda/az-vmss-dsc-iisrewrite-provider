Configuration InstallIIS
# Configuration Main
{
    Param (
        [string] $nodeName = "localhost",
        [string] $assemblyBlobPath = "https://jpda.blob.core.windows.net/shared/Microsoft.Web.Iis.Rewrite.Providers.dll?st=2017-03-30T19%3A17%3A00Z&se=2018-03-31T19%3A17%3A00Z&sp=r&sv=2015-12-11&sr=b&sig=%2BwJWk8%2FgCnDs4LRW6pxDDl5Cde7ZeilmlROlITGMwcY%3D",
        [string] $localAssemblyPath = "c:\app\",
        [string] $targetAssemblyName = "Microsoft.Web.Iis.Rewrite.Providers",
        [string] $rewriteProviderName = "DbProviderSample",
        [string] $rewriteProviderType = "DbProvider, Microsoft.Web.Iis.Rewrite.Providers, Version=7.1.761.0, Culture=neutral, PublicKeyToken=0545b0627da60a5f"
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
                return Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/providers" -name "." | select -ExpandProperty collection | Where-Object { $_.name -eq $using:rewriteProviderName}
            }
            TestScript = {
                $configBlock = Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/providers" -name "." | select -ExpandProperty collection | Where-Object { $_.name -eq $using:rewriteProviderName}
                Write-Verbose $configBlock.Length
                return $configBlock.Length -gt 0
            }
            SetScript = {
                Remove-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/providers" -name "." -AtElement @{name='$using:rewriteProviderName'}
                Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/providers" -name "." -value @{name='$using:rewriteProviderName';type='$using:rewriteProviderType'}
                Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/providers/provider[@name='$using:rewriteProviderName']/settings" -name "." -value @{key='ConnectionString';value='xon'}
            }
        }
        Script ReWriteRules {
            DependsOn = "[Package]UrlRewrite", "[Script]AddCustomRewriteProviderToIIS", "[Script]InstallRewriteAssemblyToGac"
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