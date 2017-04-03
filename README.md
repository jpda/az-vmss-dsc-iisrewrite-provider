## A DSC script for configuring custom URL Rewrite providers in IIS

This creates a VM Scale Set in Azure for the purposes of using IIS with a custom URL Rewrite provider. This template:
- Downloads custom provider assembly from blob storage (in this case, the `FileMapProvider` from the [rewrite extensibility samples](https://www.microsoft.com/en-us/download/details.aspx?id=43353))
- Installs the provider assembly into the GAC
- Installs provider into IIS at the server level (can be modified to use a different scope)
- Downloads additional files and configures the provider
- Sets up sample rewrite rule to `Default Web Site` using the `FileMapProvider`, documented [here](https://www.iis.net/learn/extensions/url-rewrite-module/using-custom-rewrite-providers-with-url-rewrite-module).

## WIP
- Azure ARM template still in-progress
- `Test-Script` for rewrite rules in [IISInstall.ps1](https://github.com/jpda/az-vmss-dsc-iisrewrite-provider/blob/master/DSC/IISInstall.ps1/IISInstall.ps1) isn't very good

### Notes
This installs the custom provider at the server level - if you want to use it only on a specific web site, add the provider in at that level and modify the paths appropriately. If you change them, remember to update your later paths. If you use it as-is, expect your web.config in the web site to only include the rewrite rules, *not* the provider declaration (e.g., the `<providers>` tag shouldn't exist in the Default Web Site's web.config, as it is already available via applicationHost.config for the whole server).

## This started life as [201-vmss-windows-webapp-dsc-autoscale](https://github.com/Azure/azure-quickstart-templates/tree/master/201-vmss-windows-webapp-dsc-autoscale)

Tags: `VMSS, VM Scale Set, Windows, DSC Extension, IIS Rewrite, IIS Custom Rewrite Provider`