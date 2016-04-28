﻿# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------

<#
.SYNOPSIS
Tests Create-AzureVM with valid information.
#>
function Test-GetAzureVM
{
    # Virtual Machine cmdlets are now showing a non-terminating error message for ResourceNotFound
    # To continue script, $ErrorActionPreference should be set to 'SilentlyContinue'.
    $tempErrorActionPreference = $ErrorActionPreference;
    $ErrorActionPreference='SilentlyContinue';

    # Setup
    $location = Get-DefaultLocation
    $imgName = Get-DefaultImage $location


    $storageName = getAssetName
    New-AzureStorageAccount -StorageAccountName $storageName -Location $location

    Set-CurrentStorageAccountName $storageName

    $vmName = "vm1"
    $svcName = Get-CloudServiceName

    # Test
    New-AzureService -ServiceName $svcName -Location $location
    New-AzureQuickVM -Windows -ImageName $imgName -Name $vmName -ServiceName $svcName -AdminUsername "pstestuser" -Password "p@ssw0rd"

    Get-AzureVM -ServiceName $svcName -Name $vmName


    # Cleanup
    Cleanup-CloudService $svcName
    $ErrorActionPreference = $tempErrorActionPreference;
}


<#
.SYNOPSIS
Test Get-AzureLocation
#>
function Test-GetAzureLocation
{
    $locations = Get-AzureLocation;

    foreach ($loc in $locations)
    {
        $svcName = getAssetName;
        $st = New-AzureService -ServiceName $svcName -Location $loc.Name;
        
        # Cleanup
        Cleanup-CloudService $svcName
    }
}

# Test Service Management Cloud Exception
function Run-ServiceManagementCloudExceptionTests
{
    $compare = "*OperationID : `'*`'";
    Assert-ThrowsLike { $st = Get-AzureService -ServiceName '*' } $compare;
    Assert-ThrowsLike { $st = Get-AzureVM -ServiceName '*' } $compare;
    Assert-ThrowsLike { $st = Get-AzureAffinityGroup -Name '*' } $compare;
}

# Test Start/Stop-AzureVM for Multiple VMs
function Run-StartAndStopMultipleVirtualMachinesTest
{
    # Virtual Machine cmdlets are now showing a non-terminating error message for ResourceNotFound
    # To continue script, $ErrorActionPreference should be set to 'SilentlyContinue'.
    $tempErrorActionPreference = $ErrorActionPreference;
    $ErrorActionPreference='SilentlyContinue';

    # Setup
    $location = Get-DefaultLocation;
    $imgName = Get-DefaultImage $location;

    $storageName = 'pstest' + (getAssetName);
    New-AzureStorageAccount -StorageAccountName $storageName -Location $location;

    # Associate the new storage account with the current subscription
    Set-CurrentStorageAccountName $storageName;

    $vmNameList = @("vm01", "vm02", "test04");
    $svcName = 'pstest' + (Get-CloudServiceName);
    $userName = "pstestuser";
    $password = "p@ssw0rd";

    # Test
    New-AzureService -ServiceName $svcName -Location $location;

    try
    {
        foreach ($vmName in $vmNameList)
        {
            New-AzureQuickVM -Windows -ImageName $imgName -Name $vmName -ServiceName $svcName -AdminUsername $userName -Password $password;
        }

        # Get VM List
        $vmList = Get-AzureVM -ServiceName $svcName;

        # Test Stop
        Stop-AzureVM -Force -ServiceName $svcName -Name $vmNameList[0];
        Stop-AzureVM -Force -ServiceName $svcName -Name $vmNameList[0],$vmNameList[1];
        Stop-AzureVM -Force -ServiceName $svcName -Name $vmNameList;
        Stop-AzureVM -Force -ServiceName $svcName -Name '*';
        Stop-AzureVM -Force -ServiceName $svcName -Name 'vm*';
        Stop-AzureVM -Force -ServiceName $svcName -Name 'vm*','test*';
        Stop-AzureVM -Force -ServiceName $svcName -VM $vmList[0];
        Stop-AzureVM -Force -ServiceName $svcName -VM $vmList[0],$vmList[1];
        Stop-AzureVM -Force -ServiceName $svcName -VM $vmList;

        # Test Start
        Start-AzureVM -ServiceName $svcName -Name $vmNameList[0];
        Start-AzureVM -ServiceName $svcName -Name $vmNameList[0],$vmNameList[1];
        Start-AzureVM -ServiceName $svcName -Name $vmNameList;
        Start-AzureVM -ServiceName $svcName -Name '*';
        Start-AzureVM -ServiceName $svcName -Name 'vm*';
        Start-AzureVM -ServiceName $svcName -Name 'vm*','test*';
        Start-AzureVM -ServiceName $svcName -VM $vmList[0];
        Start-AzureVM -ServiceName $svcName -VM $vmList[0],$vmList[1];
        Start-AzureVM -ServiceName $svcName -VM $vmList;
    }
    finally
    {
        # Cleanup
        Cleanup-CloudService $svcName;
        $ErrorActionPreference = $tempErrorActionPreference;
    }
}

# Run Auto-Generated Hosted Service Cmdlet Tests
function Run-AutoGeneratedHostedServiceCmdletTests
{
    # Setup
    $location = Get-DefaultLocation;
    $imgName = Get-DefaultImage $location;

    $storageName = 'pstest' + (getAssetName);
    New-AzureStorageAccount -StorageAccountName $storageName -Location $location;

    # Associate the new storage account with the current subscription
    Set-CurrentStorageAccountName $storageName;

    $vmNameList = @("vm01", "vm02", "test04");
    $svcName = 'pstest' + (Get-CloudServiceName);
    $userName = "pstestuser";
    $password = "p@ssw0rd";

    try
    {
        # Create Parameters
        $svcCreateParams = New-AzureComputeParameterObject -FriendlyName 'HostedServiceCreateParameters';
        $svcCreateParams.ServiceName = $svcName;
        $svcCreateParams.Location = $location;
        $svcCreateParams.Description = $svcName;
        $svcCreateParams.Label = $svcName;

        # Invoke Create
        $st = Invoke-AzureComputeMethod -MethodName 'HostedServiceCreate' -HostedServiceCreateParameters $svcCreateParams;

        Assert-AreEqual $st.StatusCode 'Created';
        Assert-NotNull $st.RequestId;

        # Invoke Get
        $svcGetResult = Invoke-AzureComputeMethod -MethodName 'HostedServiceGet' -ServiceName $svcName;
        Assert-AreEqual $svcGetResult.ServiceName $svcName;
        Assert-AreEqual $svcGetResult.Properties.Description $svcName;
        Assert-AreEqual $svcGetResult.Properties.Label $svcName;

        # Update Parameters
        $svcUpdateParams = New-AzureComputeParameterObject -FriendlyName 'HostedServiceUpdateParameters';
        $svcUpdateParams.Description = 'update1';
        $svcUpdateParams.Label = 'update2';

        # Invoke Update
        $svcGetResult2 = Invoke-AzureComputeMethod -MethodName 'HostedServiceUpdate' -ServiceName $svcName -HostedServiceUpdateParameters $svcUpdateParams;

        # Invoke Get
        $svcGetResult2 = Invoke-AzureComputeMethod -MethodName 'HostedServiceGet' -ServiceName $svcName;
        Assert-AreEqual $svcGetResult2.ServiceName $svcName;
        Assert-AreEqual $svcGetResult2.Properties.Description $svcUpdateParams.Description;
        Assert-AreEqual $svcGetResult2.Properties.Label $svcUpdateParams.Label;

        # Invoke List
        $svcListResult = Invoke-AzureComputeMethod -MethodName 'HostedServiceList';
        Assert-True { ($svcListResult | where { $_.ServiceName -eq $svcName }).Count -gt 0 };

        # Invoke Delete
        $st = Invoke-AzureComputeMethod -MethodName 'HostedServiceDelete' -ServiceName $svcName;
        Assert-AreEqual $st.StatusCode 'OK';
        Assert-NotNull $st.RequestId;
    }
    finally
    {
        # Cleanup
        Cleanup-CloudService $svcName;
    }
}

# Run Auto-Generated Virtual Machine Cmdlet Tests
function Run-AutoGeneratedVirtualMachineCmdletTests
{
    # Setup
    $location = Get-DefaultLocation;

    $storageName = 'pstest' + (getAssetName);
    New-AzureStorageAccount -StorageAccountName $storageName -Location $location;

    # Associate the new storage account with the current subscription
    Set-CurrentStorageAccountName $storageName;

    $svcName = 'pstest' + (Get-CloudServiceName);
    $userName = "pstestuser";
    $password = "p@ssw0rd";

    try
    {
        # Create Hosted Service Parameters
        $svcCreateParams = New-AzureComputeParameterObject -FriendlyName 'HostedServiceCreateParameters';
        $svcCreateParams.ServiceName = $svcName;
        $svcCreateParams.Location = $location;
        $svcCreateParams.Description = $svcName;
        $svcCreateParams.Label = $svcName;

        # Invoke Hosted Service Create
        $st = Invoke-AzureComputeMethod -MethodName 'HostedServiceCreate' -ArgumentList $svcCreateParams;
        Assert-AreEqual $st.StatusCode 'Created';
        Assert-NotNull $st.RequestId;

        # Invoke Hosted Service Get
        $svcGetResult = Invoke-AzureComputeMethod -MethodName 'HostedServiceGet' -ArgumentList $svcName;
        Assert-AreEqual $svcGetResult.ServiceName $svcName;
        Assert-AreEqual $svcGetResult.Properties.Description $svcName;
        Assert-AreEqual $svcGetResult.Properties.Label $svcName;

        # Invoke Virtual Machine OS Image List
        $images = (Invoke-AzureComputeMethod -MethodName 'VirtualMachineOSImageList').Images;
        $image = $images | where { $_.OperatingSystemType -eq 'Windows' -and $_.LogicalSizeInGB -le 100 } | select -First 1;

        # Create Virtual Machine Deployment Create Parameters
        $vmDeployment = New-AzureComputeParameterObject -FriendlyName 'VirtualMachineCreateDeploymentParameters';
        $vmDeployment.Name = $svcName;
        $vmDeployment.Label = $svcName;
        $vmDeployment.DeploymentSlot = 'Production';
        $vmDeployment.Roles = New-AzureComputeParameterObject -FriendlyName 'VirtualMachineRoleList';
        $vmDeployment.Roles.Add((New-AzureComputeParameterObject -FriendlyName 'VirtualMachineRole'));
        $vmDeployment.Roles[0].RoleName = $svcName;
        $vmDeployment.Roles[0].RoleSize = 'Large';
        $vmDeployment.Roles[0].RoleType = 'PersistentVMRole';
        $vmDeployment.Roles[0].ProvisionGuestAgent = $false;
        $vmDeployment.Roles[0].ResourceExtensionReferences = $null;
        $vmDeployment.Roles[0].DataVirtualHardDisks = $null;
        $vmDeployment.Roles[0].OSVirtualHardDisk = New-AzureComputeParameterObject -FriendlyName 'VirtualMachineOSVirtualHardDisk';
        $vmDeployment.Roles[0].OSVirtualHardDisk.SourceImageName = $image.Name;
        $vmDeployment.Roles[0].OSVirtualHardDisk.MediaLink = "http://${storageName}.blob.core.windows.net/myvhds/${svcName}.vhd";
        $vmDeployment.Roles[0].OSVirtualHardDisk.ResizedSizeInGB = 128;
        $vmDeployment.Roles[0].OSVirtualHardDisk.HostCaching = 'ReadWrite';
        $vmDeployment.Roles[0].ConfigurationSets = New-AzureComputeParameterObject -FriendlyName 'VirtualMachineConfigurationSetList';
        $vmDeployment.Roles[0].ConfigurationSets.Add((New-AzureComputeParameterObject -FriendlyName 'VirtualMachineConfigurationSet'));
        $vmDeployment.Roles[0].ConfigurationSets[0].ConfigurationSetType = "WindowsProvisioningConfiguration";
        $vmDeployment.Roles[0].ConfigurationSets[0].AdminUserName = $userName;
        $vmDeployment.Roles[0].ConfigurationSets[0].AdminPassword = $password;
        $vmDeployment.Roles[0].ConfigurationSets[0].ComputerName = 'test';
        $vmDeployment.Roles[0].ConfigurationSets[0].HostName = "${svcName}.cloudapp.net";
        $vmDeployment.Roles[0].ConfigurationSets[0].EnableAutomaticUpdates = $false;
        $vmDeployment.Roles[0].ConfigurationSets[0].TimeZone = "Pacific Standard Time";

        # Invoke Virtual Machine Create Deployment
        $st = Invoke-AzureComputeMethod -MethodName 'VirtualMachineCreateDeployment' -ArgumentList $svcName,$vmDeployment;
        Assert-AreEqual $st.StatusCode 'OK';
        Assert-NotNull $st.RequestId;

        # Invoke Virtual Machine Get
        $st = Invoke-AzureComputeMethod -MethodName 'VirtualMachineGet' -ArgumentList $svcName,$svcName,$svcName;
        Assert-AreEqual $st.RoleName $svcName;

        # Invoke Hosted Service Delete
        $st = Invoke-AzureComputeMethod -MethodName 'HostedServiceDeleteAll' -ArgumentList $svcName;
        Assert-AreEqual $st.StatusCode 'OK';
        Assert-NotNull $st.RequestId;
    }
    finally
    {
        # Cleanup
        Cleanup-CloudService $svcName;
    }
}


# Run New-AzureComputeArgumentList Cmdlet Tests Using Method Names
function Run-NewAzureComputeArgumentListTests
{
    $command = Get-Command -Name 'New-AzureComputeArgumentList';
    $all_methods = $command.Parameters['MethodName'].Attributes.ValidValues;

    foreach ($method in $all_methods)
    {
        $args = New-AzureComputeArgumentList -MethodName $method;
        foreach ($arg in $args)
        {
            Assert-NotNull $arg;
        }

        Write-Verbose "Invoke-AzureComputeMethod -MethodName $method -ArgumentList $args;";

        if ($args.Count -gt 0)
        {
            # If the method requires any inputs, empty/null input call would fail
            Assert-Throws { Invoke-AzureComputeMethod -MethodName $method -ArgumentList $args; }
        }
        else
        {
            # If the method doesn't requires any inputs, it shall succeed.
            $st = Invoke-AzureComputeMethod -MethodName $method;
        }
    }
}


# Run New-AzureComputeParameterObject Cmdlet Tests
function Run-NewAzureComputeParameterObjectTests
{
    $command = Get-Command -Name 'New-AzureComputeParameterObject';

    $all_friendly_names = $command.Parameters['FriendlyName'].Attributes.ValidValues;
    foreach ($friendly_name in $all_friendly_names)
    {
        $param = New-AzureComputeParameterObject -FriendlyName $friendly_name;
        Assert-NotNull $param;
    }

    $all_full_names = $command.Parameters['FullName'].Attributes.ValidValues;
    foreach ($full_name in $all_full_names)
    {
        $param = New-AzureComputeParameterObject -FullName $full_name;
        Assert-NotNull $param;

        $param_type_name = $param.GetType().ToString().Replace('+', '.');
        $full_name_query = $full_name.Replace('+', '.').Replace('<', '*').Replace('>', '*');
        Assert-True { $param_type_name -like $full_name_query } "`'$param_type_name`' & `'$full_name`'";
    }
}

# Run Set-AzurePlatformVMImage Cmdlet Negative Tests
function Run-AzurePlatformVMImageNegativeTest
{
    $location = Get-DefaultLocation;
    $imgName = Get-DefaultImage $location;
    $replicate_locations = (Get-AzureLocation | where { $_.Name -like '*US*' } | select -ExpandProperty Name);

    $c1 = New-AzurePlatformComputeImageConfig -Offer test -Sku test -Version test;
    $c2 = New-AzurePlatformMarketplaceImageConfig -PlanName test -Product test -Publisher test -PublisherId test;

    Assert-ThrowsContains `
        { Set-AzurePlatformVMImage -ImageName $imgName -ReplicaLocations $replicate_locations -ComputeImageConfig $c1 -MarketplaceImageConfig $c2 } `
        "ForbiddenError: This operation is not allowed for this subscription.";

    foreach ($mode in @("MSDN", "Private", "Public"))
    {
        Assert-ThrowsContains `
            { Set-AzurePlatformVMImage -ImageName $imgName -Permission $mode } `
            "ForbiddenError: This operation is not allowed for this subscription.";
    }
}

# Run Auto-Generated Service Extension Cmdlet Tests
function Run-AutoGeneratedServiceExtensionCmdletTests
{
    # Setup
    $location = Get-DefaultLocation;

    $storageName = 'pstest' + (getAssetName);
    New-AzureStorageAccount -StorageAccountName $storageName -Location $location;

    # Associate the new storage account with the current subscription
    Set-CurrentStorageAccountName $storageName;

    $svcName = 'pstest' + (Get-CloudServiceName);

    try
    {
        # Create Hosted Service Parameters
        $svcCreateParams = New-AzureComputeParameterObject -FriendlyName 'HostedServiceCreateParameters';
        $svcCreateParams.ServiceName = $svcName;
        $svcCreateParams.Location = $location;
        $svcCreateParams.Description = $svcName;
        $svcCreateParams.Label = $svcName;

        # Invoke Hosted Service Create
        $st = Invoke-AzureComputeMethod -MethodName 'HostedServiceCreate' -ArgumentList $svcCreateParams;
        Assert-AreEqual $st.StatusCode 'Created';
        Assert-NotNull $st.RequestId;

        # New-AzureDeployment (in Azure.psd1)
        $testMode = Get-ComputeTestMode;
        if ($testMode.ToLower() -ne 'playback')
        {
            $cspkg = '.\Resources\ServiceManagement\Files\OneWebOneWorker.cspkg';
        }
        else
        {
            $cspkg = "https://${storageName}.blob.azure.windows.net/blob/OneWebOneWorker.cspkg";
        }
        $cscfg = "$TestOutputRoot\Resources\ServiceManagement\Files\OneWebOneWorker.cscfg";

        $st = New-AzureDeployment -ServiceName $svcName -Package $cspkg -Configuration $cscfg -Label $svcName -Slot Production;

        $deployment = Get-AzureDeployment -ServiceName $svcName -Slot Production;
        $config = $deployment.Configuration;

        # Invoke Hosted Service Add Extension
        $p1 = New-AzureComputeArgumentList -MethodName HostedServiceAddExtension;
        $p1[0].Value = $svcName;
        $p1[1].Value.Id = 'test';
        $p1[1].Value.PublicConfiguration =
@"
<?xml version="1.0" encoding="UTF-8"?>
<PublicConfig>
  <UserName>pstestuser</UserName>
  <Expiration></Expiration>
</PublicConfig>
"@;
        $p1[1].Value.PrivateConfiguration =
@"
<?xml version="1.0" encoding="UTF-8"?>
<PrivateConfig>
  <Password>pstestuser</Password>
</PrivateConfig>
"@;
        $p1[1].Value.ProviderNamespace = 'Microsoft.Windows.Azure.Extensions';
        $p1[1].Value.Type = 'RDP';
        $p1[1].Value.Version = '1.*';
        $d1 = ($p1 | select -ExpandProperty Value);
        $st = Invoke-AzureComputeMethod -MethodName HostedServiceAddExtension -ArgumentList $d1;

        # Invoke Deployment Change Configuration
        $p2 = New-AzureComputeArgumentList -MethodName DeploymentChangeConfigurationBySlot;
        $p2[0].Value = $svcName;
        $p2[1].Value = [Microsoft.WindowsAzure.Management.Compute.Models.DeploymentSlot]::Production;
        $p2[2].Value = New-Object -TypeName Microsoft.WindowsAzure.Management.Compute.Models.DeploymentChangeConfigurationParameters;
        $p2[2].Value.Configuration = $deployment.Configuration;
        $p2[2].Value.ExtensionConfiguration = New-Object -TypeName Microsoft.WindowsAzure.Management.Compute.Models.ExtensionConfiguration;
        $p2[2].Value.ExtensionConfiguration.AllRoles.Add('test');
        $d2 = ($p2 | select -ExpandProperty Value);
        $st = Invoke-AzureComputeMethod -MethodName DeploymentChangeConfigurationBySlot -ArgumentList $d2;

        # Invoke Hosted Service Delete
        $st = Invoke-AzureComputeMethod -MethodName 'HostedServiceDeleteAll' -ArgumentList $svcName;
        Assert-AreEqual $st.StatusCode 'OK';
        Assert-NotNull $st.RequestId;
    }
    finally
    {
        # Cleanup
        Cleanup-CloudService $svcName;
    }
}

# Run Service Extension Set Cmdlet Tests
function Run-ServiceExtensionSetCmdletTests
{
    # Setup
    $location = Get-DefaultLocation;
    $imgName = Get-DefaultImage $location;

    $storageName = 'pstest' + (getAssetName);
    New-AzureStorageAccount -StorageAccountName $storageName -Location $location;

    # Associate the new storage account with the current subscription
    Set-CurrentStorageAccountName $storageName;

    $svcName = 'pstest' + (Get-CloudServiceName);
    $userName = "pstestuser";
    $password = "p@ssw0rd";
    $sPassword = ConvertTo-SecureString $password -AsPlainText -Force;
    $credential = New-Object System.Management.Automation.PSCredential ($userName, $sPassword);

    # Test
    New-AzureService -ServiceName $svcName -Location $location;

    try
    {
        # New-AzureDeployment (in Azure.psd1)
        $testMode = Get-ComputeTestMode;
        if ($testMode.ToLower() -ne 'playback')
        {
            $cspkg = '.\Resources\ServiceManagement\Files\OneWebOneWorker.cspkg';
        }
        else
        {
            $cspkg = "https://${storageName}.blob.azure.windows.net/blob/OneWebOneWorker.cspkg";
        }
        $cscfg = "$TestOutputRoot\Resources\ServiceManagement\Files\OneWebOneWorker.cscfg";

        # Staging 1st
        $st = New-AzureDeployment -ServiceName $svcName -Package $cspkg -Configuration $cscfg -Label $svcName -Slot Staging;
        $st = Set-AzureServiceRemoteDesktopExtension -ServiceName $svcName -Slot Staging -Credential $credential;
        $ex = Get-AzureServiceExtension -ServiceName $svcName -Slot Staging;
        $st = Move-AzureDeployment -ServiceName $svcName;
        $ex = Get-AzureServiceExtension -ServiceName $svcName -Slot Production;

        # Staging 2nd
        $st = New-AzureDeployment -ServiceName $svcName -Package $cspkg -Configuration $cscfg -Label $svcName -Slot Staging;
        $st = Set-AzureServiceRemoteDesktopExtension -ServiceName $svcName -Slot Staging -Credential $credential;
        $ex = Get-AzureServiceExtension -ServiceName $svcName -Slot Staging;
        $st = Move-AzureDeployment -ServiceName $svcName;
        $ex = Get-AzureServiceExtension -ServiceName $svcName -Slot Production;

        # Set Extensions
        $st = Set-AzureServiceRemoteDesktopExtension -ServiceName $svcName -Slot Production -Credential $credential;
        $st = Set-AzureServiceRemoteDesktopExtension -ServiceName $svcName -Slot Staging -Credential $credential;
    }
    finally
    {
        # Cleanup
        Cleanup-CloudService $svcName;
    }
}


# Run Service Deployment Extension Cmdlet Tests
function Run-ServiceDeploymentExtensionCmdletTests
{
    # Setup
    $location = Get-DefaultLocation;
    $imgName = Get-DefaultImage $location;

    $storageName = 'pstest' + (getAssetName);
    New-AzureStorageAccount -StorageAccountName $storageName -Location $location;

    # Associate the new storage account with the current subscription
    Set-CurrentStorageAccountName $storageName;

    $svcName = 'pstest' + (Get-CloudServiceName);
    $userName = "pstestuser";
    $password = "p@ssw0rd";
    $sPassword = ConvertTo-SecureString $password -AsPlainText -Force;
    $credential = New-Object System.Management.Automation.PSCredential ($userName, $sPassword);

    # Test
    New-AzureService -ServiceName $svcName -Location $location;

    try
    {
        # New-AzureDeployment (in Azure.psd1)
        $testMode = Get-ComputeTestMode;
        if ($testMode.ToLower() -ne 'playback')
        {
            $cspkg = "$TestOutputRoot\Resources\ServiceManagement\Files\LongRoleName.Cloud.cspkg";
        }
        else
        {
            $cspkg = "https://${storageName}.blob.azure.windows.net/blob/LongRoleName.Cloud.cspkg";
        }
        $cscfg = "$TestOutputRoot\Resources\ServiceManagement\Files\LongRoleName.Cloud.cscfg";

        $webRoleNameWithSpaces = "WebRole1 With Spaces In Name";
        $workerRoleLongName = "Microsoft.Contoso.Department.ProjectCodeName.Worker";
        $rdpCfg1 = New-AzureServiceRemoteDesktopExtensionConfig -Credential $credential -Role $webRoleNameWithSpaces
        $rdpCfg2 = New-AzureServiceRemoteDesktopExtensionConfig -Credential $credential -Role $workerRoleLongName;
        $adCfg1 = New-AzureServiceADDomainExtensionConfig -Role $webRoleNameWithSpaces -WorkgroupName 'test1';
        $adCfg2 = New-AzureServiceADDomainExtensionConfig -Role $workerRoleLongName -WorkgroupName 'test2';

        $st = New-AzureDeployment -ServiceName $svcName -Package $cspkg -Configuration $cscfg -Label $svcName -Slot Production -ExtensionConfiguration $rdpCfg1,$adCfg1;
        $exts = Get-AzureServiceExtension -ServiceName $svcName -Slot Production;
        Assert-True { $exts.Count -eq 2 };

        $st = New-AzureDeployment -ServiceName $svcName -Package $cspkg -Configuration $cscfg -Label $svcName -Slot Staging -ExtensionConfiguration $rdpCfg2,$adCfg2;
        $exts = Get-AzureServiceExtension -ServiceName $svcName -Slot Staging;
        Assert-True { $exts.Count -eq 2 };

        $st = Set-AzureDeployment -Config -ServiceName $svcName -Configuration $cscfg -Slot Production -ExtensionConfiguration $rdpCfg2;
        $exts = Get-AzureServiceExtension -ServiceName $svcName -Slot Production;
        Assert-True { $exts.Count -eq 1 };

        $st = Set-AzureDeployment -Config -ServiceName $svcName -Configuration $cscfg -Slot Staging -ExtensionConfiguration $rdpCfg1,$adCfg1;
        $exts = Get-AzureServiceExtension -ServiceName $svcName -Slot Staging;
        Assert-True { $exts.Count -eq 2 };
    }
    finally
    {
        # Cleanup
        Cleanup-CloudService $svcName;
    }
}

# Run Data Collection Cmdlet Tests
function Run-EnableAndDisableDataCollectionTests
{
    $st = Enable-AzureDataCollection;

    $locations = Get-AzureLocation;
    foreach ($loc in $locations)
    {
        $svcName = getAssetName;
        $st = New-AzureService -ServiceName $svcName -Location $loc.Name;
        
        # Cleanup
        Cleanup-CloudService $svcName
    }

    $st = Disable-AzureDataCollection;
}

<#
.SYNOPSIS
Tests Move-AzureService
#>
function Test-MigrateAzureDeployment
{
    # Virtual Machine cmdlets are now showing a non-terminating error message for ResourceNotFound
    # To continue script, $ErrorActionPreference should be set to 'SilentlyContinue'.
    $tempErrorActionPreference = $ErrorActionPreference;
    $ErrorActionPreference='SilentlyContinue';

    # Setup
    $location = Get-DefaultLocation
    $imgName = Get-DefaultImage $location

    $storageName = getAssetName
    New-AzureStorageAccount -StorageAccountName $storageName -Location $location

    Set-CurrentStorageAccountName $storageName

    $vmName = "vm1"
    $svcName = Get-CloudServiceName

    # Test
    New-AzureService -ServiceName $svcName -Location $location
    New-AzureQuickVM -Windows -ImageName $imgName -Name $vmName -ServiceName $svcName -AdminUsername "pstestuser" -Password "p@ssw0rd"

    Get-AzureVM -ServiceName $svcName -Name $vmName

    Move-AzureService -Prepare -ServiceName $svcName -DeploymentName $svcName -CreateNewVirtualNetwork;

    $vm = Get-AzureVM -ServiceName $svcName -Name $vmName;

    Assert-AreEqual "Prepared" $vm.VM.MigrationState;

    Move-AzureService -Commit -ServiceName $svcName -DeploymentName $svcName;

    $vm = Get-AzureVM -ServiceName $svcName -Name $vmName;

    Assert-AreEqual "CommitFailed" $vm.VM.MigrationState

    # Try again
    #Move-AzureService -Commit -ServiceName $svcName -DeploymentName $svcName;
    #Get-AzureVM -ServiceName $svcName -Name $vmName;

    # Cleanup
    Cleanup-CloudService $svcName
    $ErrorActionPreference = $tempErrorActionPreference;
}

<#
.SYNOPSIS
Tests Move-AzureService with Abort
#>
function Test-MigrationAbortAzureDeployment
{
    # Virtual Machine cmdlets are now showing a non-terminating error message for ResourceNotFound
    # To continue script, $ErrorActionPreference should be set to 'SilentlyContinue'.
    $tempErrorActionPreference = $ErrorActionPreference;
    $ErrorActionPreference='SilentlyContinue';

    # Setup
    $location = Get-DefaultLocation
    $imgName = Get-DefaultImage $location

    $storageName = getAssetName
    New-AzureStorageAccount -StorageAccountName $storageName -Location $location

    Set-CurrentStorageAccountName $storageName

    $vmName = "vm1"
    $svcName = Get-CloudServiceName

    # Test
    New-AzureService -ServiceName $svcName -Location $location
    New-AzureQuickVM -Windows -ImageName $imgName -Name $vmName -ServiceName $svcName -AdminUsername "pstestuser" -Password "p@ssw0rd"

    Get-AzureVM -ServiceName $svcName -Name $vmName

    Move-AzureService -Prepare -ServiceName $svcName -DeploymentName $svcName -CreateNewVirtualNetwork;

    Get-AzureVM -ServiceName $svcName -Name $vmName;

    Assert-AreEqual "Prepared" $vm.VM.MigrationState;

    Move-AzureService -Abort -ServiceName $svcName -DeploymentName $svcName;

    Get-AzureVM -ServiceName $svcName -Name $vmName;

    # Cleanup
    Cleanup-CloudService $svcName
    $ErrorActionPreference = $tempErrorActionPreference;
}

<#
.SYNOPSIS
Tests Move-AzureVirtualNetwork with Prepare and Commit
#>
function Test-MigrateAzureVNet
{
    # Setup
    $location = Get-DefaultLocation
    $affName = "WestUsAffinityGroup";
    $vnetConfigPath = ".\Resources\ServiceManagement\Files\vnetconfig.netcfg";
    $vnetName = "NewVNet1";

    # Test

    Set-AzureVNetConfig -ConfigurationPath $vnetConfigPath;

    Get-AzureVNetSite;

    Move-AzureVirtualNetwork -Prepare -VirtualNetworkName $vnetName;

    Get-AzureVNetSite;

    Move-AzureVirtualNetwork -Commit -VirtualNetworkName $vnetName;

    Get-AzureVNetSite;

    # Cleanup
    Remove-AzureVNetConfig
}

<#
.SYNOPSIS
Tests Move-AzureVirtualNetwork with Prepare and Abort
#>
function Test-MigrationAbortAzureVNet
{
    # Setup
    $location = Get-DefaultLocation
    $affName = "WestUsAffinityGroup";
    $vnetConfigPath = ".\Resources\ServiceManagement\Files\vnetconfig.netcfg";
    $vnetName = "NewVNet1";

    # Test

    Set-AzureVNetConfig -ConfigurationPath $vnetConfigPath;

    Get-AzureVNetSite;

    Move-AzureVirtualNetwork -Prepare -VirtualNetworkName $vnetName;

    Get-AzureVNetSite;

    Move-AzureVirtualNetwork -Abort -VirtualNetworkName $vnetName;

    Get-AzureVNetSite;

    # Cleanup
    Remove-AzureVNetConfig
}


function Test-NewAzureVMWithBYOL
{
    # Virtual Machine cmdlets are now showing a non-terminating error message for ResourceNotFound
    # To continue script, $ErrorActionPreference should be set to 'SilentlyContinue'.
    $tempErrorActionPreference = $ErrorActionPreference;
    $ErrorActionPreference='SilentlyContinue';

    # Setup
    $location = "Central US";
    $storageName = "mybyolosimagerdfe";

    $vm1Name = "vm1";
    $vm2Name = "vm2";
    $svcName = Get-CloudServiceName;

    $vmSize = "Small";
    $licenseType = "Windows_Server";
    $imgName = getAssetName;
    $userName = "User" + $svcName;
    $pass = "User@" + $svcName;

    $media1 = "http://mybyolosimagerdfe.blob.core.windows.net/myvhd/" + $svcName + "0.vhd";
    $media2 = "http://mybyolosimagerdfe.blob.core.windows.net/myvhd/" + $svcName + "1.vhd";

    Set-CurrentStorageAccountName $storageName;

    Add-AzureVMImage -ImageName $imgName `
        -MediaLocation "https://mybyolosimagerdfe.blob.core.windows.net/vhdsrc/win2012-tag0.vhd" `
        -OS "Windows" `
        -Label "BYOL Image" `
        -RecommendedVMSize $vmSize `
        -IconUri "http://www.bing.com" `
        -SmallIconUri "http://www.bing.com" `
        -ShowInGui;

    # Test
    New-AzureService -ServiceName $svcName -Location $location;

    $vm1 = New-AzureVMConfig -Name $vm1Name -ImageName $imgName -InstanceSize $vmSize `
         -LicenseType $licenseType -HostCaching ReadWrite -MediaLocation $media1;

    $vm1 = Add-AzureProvisioningConfig -VM $vm1 -Windows -Password $pass -AdminUsername $userName;

    $vm2 = New-AzureVMConfig -Name $vm2Name -ImageName $imgName -InstanceSize $vmSize `
         -LicenseType $licenseType -HostCaching ReadWrite -MediaLocation $media2;

    $vm2 = Add-AzureProvisioningConfig -VM $vm2 -Windows -Password $pass -AdminUsername $userName;

    New-AzureVM -ServiceName $svcName -VMs $vm1,$vm2

    $vm1result = Get-AzureVM -ServiceName $svcName -Name $vm1Name;
    $vm2result = Get-AzureVM -ServiceName $svcName -Name $vm2Name;

    Update-AzureVM -ServiceName $svcName -Name $vm1Name -VM $vm1result.VM;

    $vm1result = Get-AzureVM -ServiceName $svcName -Name $vm1Name;
    $vm2result = Get-AzureVM -ServiceName $svcName -Name $vm2Name;

    Remove-AzureService -ServiceName $svcName;

    Remove-AzureVMImage -ImageName $imgName;

    # Cleanup
    Cleanup-CloudService $svcName
    $ErrorActionPreference = $tempErrorActionPreference;
}
