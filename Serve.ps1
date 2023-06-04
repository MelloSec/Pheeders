# Import the Azure PowerShell module
Import-Module Az

$rg = "Phishing"
$name = "BlueBeamRevu"
$rgName = $rg
$nsgName = "Scoping"
$location = "eastus"
$target1 = "31.42.12.23"
$target2 = "31.42.12.24"
$cloud1 = "12.24.13.16"
$cloud2 = "21.42.31.61"

# Create new NSG object
$nsg = New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName -Location $location


# Make this a function, hashtables then loop the part where we set the NSG rules
# Add inbound security rules to NSG
$nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName
$Params1 = @{
    'Name'                     = 'allowOrg'
    'NetworkSecurityGroup'     = $nsg
    'Protocol'                 = 'TCP'
    'Direction'                = 'Inbound'
    'Priority'                 = 100
    'SourceAddressPrefix'      = $target1
    'SourcePortRange'          = '*'
    'DestinationAddressPrefix' = '*'
    'DestinationPortRange'     = '443'
    'Access'                   = 'Allow'
  }
  
  $Params2 = @{
    'Name'                     = 'allowCloud'
    'NetworkSecurityGroup'     = $nsg
    'Protocol'                 = 'TCP'
    'Direction'                = 'Inbound'
    'Priority'                 = 101
    'SourceAddressPrefix'      = $cloud
    'SourcePortRange'          = '*'
    'DestinationAddressPrefix' = '*'
    'DestinationPortRange'     = '443'
    'Access'                   = 'Allow'
  }

  $Params3 = @{
    'Name'                     = 'allowOperator'
    'NetworkSecurityGroup'     = $nsg
    'Protocol'                 = 'TCP'
    'Direction'                = 'Inbound'
    'Priority'                 = 102
    'SourceAddressPrefix'      = $lab
    'SourcePortRange'          = '*'
    'DestinationAddressPrefix' = '*'
    'DestinationPortRange'     = '443'
    'Access'                   = 'Allow'
  }
  $Params4 = @{
    'Name'                     = 'allowOrghttp'
    'NetworkSecurityGroup'     = $nsg
    'Protocol'                 = 'TCP'
    'Direction'                = 'Inbound'
    'Priority'                 = 103
    'SourceAddressPrefix'      = $target1
    'SourcePortRange'          = '*'
    'DestinationAddressPrefix' = '*'
    'DestinationPortRange'     = '80'
    'Access'                   = 'Allow'
  }
  $Params5 = @{
    'Name'                     = 'allowCloudhttp'
    'NetworkSecurityGroup'     = $nsg
    'Protocol'                 = 'TCP'
    'Direction'                = 'Inbound'
    'Priority'                 = 104
    'SourceAddressPrefix'      = $cloud1
    'SourcePortRange'          = '*'
    'DestinationAddressPrefix' = '*'
    'DestinationPortRange'     = '80'
    'Access'                   = 'Allow'
  }
  $Params6 = @{
    'Name'                     = 'allowOperatorhttp'
    'NetworkSecurityGroup'     = $nsg
    'Protocol'                 = 'TCP'
    'Direction'                = 'Inbound'
    'Priority'                 = 105
    'SourceAddressPrefix'      = $cloud2
    'SourcePortRange'          = '*'
    'DestinationAddressPrefix' = '*'
    'DestinationPortRange'     = '80'
    'Access'                   = 'Allow'
  }
  $Params7 = @{
    'Name'                     = 'allowTarget'
    'NetworkSecurityGroup'     = $nsg
    'Protocol'                 = 'TCP'
    'Direction'                = 'Inbound'
    'Priority'                 = 105
    'SourceAddressPrefix'      = $target2
    'SourcePortRange'          = '*'
    'DestinationAddressPrefix' = '*'
    'DestinationPortRange'     = '80'
    'Access'                   = 'Allow'
  }
  $Params8 = @{
    'Name'                     = 'allowTargethttp'
    'NetworkSecurityGroup'     = $nsg
    'Protocol'                 = 'TCP'
    'Direction'                = 'Inbound'
    'Priority'                 = 105
    'SourceAddressPrefix'      = $target2
    'SourcePortRange'          = '*'
    'DestinationAddressPrefix' = '*'
    'DestinationPortRange'     = '80'
    'Access'                   = 'Allow'
  }


# Deny block

  $Params99 = @{
    'Name'                     = 'denyInbound'
    'NetworkSecurityGroup'     = $nsg
    'Protocol'                 = 'TCP'
    'Direction'                = 'Inbound'
    'Priority'                 = 200
    'SourceAddressPrefix'      = '*'
    'SourcePortRange'          = '*'
    'DestinationAddressPrefix' = '*'
    'DestinationPortRange'     = '*'
    'Access'                   = 'Deny'
  }

  Add-AzNetworkSecurityRuleConfig @Params1 | Set-AzNetworkSecurityGroup
  Add-AzNetworkSecurityRuleConfig @Params2 | Set-AzNetworkSecurityGroup
  Add-AzNetworkSecurityRuleConfig @Params3 | Set-AzNetworkSecurityGroup
  Add-AzNetworkSecurityRuleConfig @Params4 | Set-AzNetworkSecurityGroup
  Add-AzNetworkSecurityRuleConfig @Params5 | Set-AzNetworkSecurityGroup
  Add-AzNetworkSecurityRuleConfig @Params6 | Set-AzNetworkSecurityGroup
  Add-AzNetworkSecurityRuleConfig @Params7 | Set-AzNetworkSecurityGroup
  Add-AzNetworkSecurityRuleConfig @Params8 | Set-AzNetworkSecurityGroup
  
  # Deny Rule
  Add-AzNetworkSecurityRuleConfig @Params99 | Set-AzNetworkSecurityGroup


  function Deploy-Phishing {
    # Create NSG if it does not exist
    if (!(Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName -ErrorAction SilentlyContinue)) {
        Create-NSG
    }

    # Deploy web app
    cd ./phishing
    az webapp up --location $location --resource-group $rg --name $name --html --sku FREE
    cd ..
}



# Restrict WebApp access 
$Resource = Get-AzResource -ResourceType Microsoft.Web/sites -ResourceGroupName $rg -ResourceName $name
$Resource.Properties.siteConfig.ipSecurityRestrictionsDefaultAction = "Deny"
$Resource | Set-AzResource -Force

Add-AzWebAppAccessRestrictionRule -ResourceGroupName $rg -WebAppName $name `
-Name "Multi-source rule" -IpAddress "$target1,$target2,$cloud1,$cloud2" `
-Priority 100 -Action Allow

# Delete webapp and NSG
function Destroy-Phishing {
    # Delete web app
    az webapp delete --resource-group $rg --name $name

    # Delete NSG
    Remove-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName -Force
    
    # Attempt to delete again to ensure
    if($Resource = Get-AzResource -ResourceType Microsoft.Web/sites -ResourceGroupName $rg -ResourceName $name){
        $Resource | Remove-AzResource -Force
    }
    
}


# Deploy or delete resources based on the specified switch
if ($args[0] -eq "-deploy") {
    Deploy-Phishing
} elseif ($args[0] -eq "-destroy") {
    Destroy-Phishing
} else {
    Write-Host "Invalid argument. Usage: ./Serve.ps1 -deploy | -destroy"
    return
}


