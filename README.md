# az-vmss-dsc-iisrewrite-provider

## WIP
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

## This started life as [201-vmss-windows-webapp-dsc-autoscale](https://github.com/Azure/azure-quickstart-templates/tree/master/201-vmss-windows-webapp-dsc-autoscale) ##

Tags: `VMSS, VM Scale Set, Windows, DSC Extension, IIS Rewrite, IIS Custom Rewrite Provider`