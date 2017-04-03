# az-vmss-dsc-iisrewrite-provider

## WIP
- 4/3/2017 - DSC configuration working locally
- Azure ARM template still pointing to old asset location

## A DSC script for configuring custom URL Rewrite providers in IIS ##

I've added a few changes -
- Removed web app deployment
- Downloads custom provider assembly from blob (in this case, the sample assembly)
- Installs into GAC
- Installs custom provider into IIS
- Sets up rewrite rules

### Notes ###
This installs the custom provider at the server level - if you want to use it only on a specific web site, add the provider in at that level and modify the paths appropriately. If you change them, remember to update your later paths. If you use it as-is, expect your web.config in the web site to only include the rewrite rules, *not* the provider declaration (e.g., the `<providers>` tag shouldn't exist in the Default Web Site's web.config, as it is already available via applicationHost.config for the whole server).

### update 4/3/17 - 5p ##
Now adds a basic rule to `Default Web Site` using the `FileMapProvider`, documented [here](https://www.iis.net/learn/extensions/url-rewrite-module/using-custom-rewrite-providers-with-url-rewrite-module).

## This started life as 201-vmss-windows-webapp-dsc-autoscale ##
## Create/Upgrade a VM Scale Set Running IIS Configured For Autoscale ##

The following template deploys a Windows VM Scale Set (VMSS) running an IIS .NET MVC application integrated with Azure autoscale. This template can be used to demonstrate initial rollout and confiuguration with the VMSS PowerShell DSC extension, as well as the process to upgrade an application already running on a VMSS.

### VMSS Initial Deployment ###
The template deploys a Windows VMSS with a desired count of VMs in the scale set. Once the VMSS is deployed, the VMSS PowerShell DSC extension installs IIS and a default web app from a WebDeploy package. The web app is nothing fancy, it's just the default MVC web app from Visual Studio, with a slight modification that shows the version (1.0 or 2.0) on the landing page. 

The application URL is an output on ARM template. It's http://\<vmsspublicipfqdn>\/MyApp or http://\<vmsspublicip\>/MyApp. 

### VMSS Application Upgrade ###
This template can also be used to demonstrate application upgrades for VMSS leveraging ARM template deployments and the VMSS PowerShell DSC extension. 

When performing the upgrade you'll want to do two things. First, change the path of the `webDeployPackage` to `DefaultASPWebApp.v2.0.zip`, this will ensure you get the updated version of the WebDeploy package. Second change the value of `powershelldscUpdateTagVersion` to `2.0`, this ensures the DSC extension is triggered and the WebDeploy package is deployed to the VMSS. Ensure all other parameters of the template are the same as your original deployment. Once deployed, visit the applicaion URL and confirm that the page shows version 2.0.

The VMSS is configured with `"upgradePolicy : { "mode" : "Automatic" }` to perfom an automatic upgrade of the VMSS. If you'd like to have control over when running VMs are upgraded, change `Automatic` to `Manual`. Automatic upgrades can incur downtime as all VMs are upgraded at the same time. For more information please see the Azure doc [Upgrade a virtual machine scale set](https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-upgrade-scale-set). 

### Autoscale Rules ###
The Autoscale rules are configured as follows
- Sample for Percentage CPU in each VM every 1 Minute
- If the Percentage CPU is greater than 50% for 5 Minutes, then the scale out action (add more VM instances, one at a time) is triggered
- Once the scale out action is completed, the cool down period is 1 Minute


Tags: `VMSS, VM Scale Set, Windows, DSC Extension`


