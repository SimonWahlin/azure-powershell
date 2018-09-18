﻿// ----------------------------------------------------------------------------------
//
// Copyright Microsoft Corporation
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------------------------------------------------------------

using System.Collections.Generic;
using System.Management.Automation;
using Microsoft.Azure.Commands.Common.Authentication.Abstractions;
using Microsoft.Azure.Commands.ResourceManager.Common.ArgumentCompleters;
using Microsoft.Azure.Commands.Sql.Common;
using Microsoft.Azure.Commands.Sql.ManagedInstance.Model;
using Microsoft.Azure.Commands.Sql.TransparentDataEncryption.Adapter;
using Microsoft.Azure.Commands.Sql.TransparentDataEncryption.Model;
using Microsoft.Azure.Management.Internal.Resources.Utilities.Models;

namespace Microsoft.Azure.Commands.Sql.TransparentDataEncryption.Cmdlet
{
    public abstract class AzureSqlRmManagedInstanceTransparentDataEncryptionProtectorBase : AzureSqlCmdletBase<IEnumerable<AzureRmSqlManagedInstanceTransparentDataEncryptionProtectorModel>, AzureSqlDatabaseTransparentDataEncryptionArmAdapter>
    {
        /// <summary>
        /// Parameter sets
        /// </summary>
        protected const string DefaultParameterSet = "AzureSqlRmManagedInstanceTransparentDataEncryptionProtectorDefaultParameterSet";
        protected const string InputObjectParameterSet = "AzureSqlRmManagedInstanceTransparentDataEncryptionProtectorInputObjectParameterSet";
        protected const string ResourceIdParameterSet = "AzureSqlRmManagedInstanceTransparentDataEncryptionProtectorResourceIdParameterSet";

        /// <summary>
        /// Gets or sets the Managed instance Object
        /// </summary>
        [Parameter(
            Mandatory = true,
            ParameterSetName = InputObjectParameterSet,
            ValueFromPipeline = true,
            Position = 0,
            HelpMessage = "The managed instance input object")]
        [ValidateNotNullOrEmpty]
        public AzureSqlManagedInstanceModel ManagedInstance { get; set; }

        /// <summary>
        /// Gets or sets the Managed instance Resource Id
        /// </summary>
        [Parameter(
            Mandatory = true,
            ParameterSetName = ResourceIdParameterSet,
            ValueFromPipelineByPropertyName = true,
            Position = 0,
            HelpMessage = "The managed instance resource id")]
        [ValidateNotNullOrEmpty]
        [Alias("ResourceId")]
        public string ManagedInstanceResourceId { get; set; }

        /// <summary>
        /// Gets or sets the resource group name
        /// </summary>
        [Parameter(
            Mandatory = true,
            ParameterSetName = DefaultParameterSet,
            Position = 0,
            HelpMessage = "The Resource Group Name")]
        [ResourceGroupCompleter()]
        [ValidateNotNullOrEmpty]
        public override string ResourceGroupName { get; set; }

        /// <summary>
        /// Gets or sets the managed instance name
        /// </summary>
        [Parameter(
            Mandatory = true,
            ParameterSetName = DefaultParameterSet,
            Position = 1,
            HelpMessage = "The managed instance name")]
        [Alias("InputObject")]
        [ValidateNotNullOrEmpty]
        public string ManagedInstanceName { get; set; }
        
        /// <summary>
        /// Entry point for the cmdlet
        /// </summary>
        public override void ExecuteCmdlet()
        {
            switch (ParameterSetName)
            {
                case InputObjectParameterSet:
                    this.ResourceGroupName = ManagedInstance.ResourceGroupName;
                    this.ManagedInstanceName = ManagedInstance.ManagedInstanceName;
                    break;
                case ResourceIdParameterSet:
                    var resourceInfo = new ResourceIdentifier(ManagedInstanceResourceId);
                    this.ResourceGroupName = resourceInfo.ResourceGroupName;
                    this.ManagedInstanceName = resourceInfo.ResourceName;
                    break;
                default:
                    break;
            }

            base.ExecuteCmdlet();
        }

        /// <summary>
        /// Intializes the model adapter
        /// </summary>
        /// <param name="subscription">The subscription the cmdlets are operation under</param>
        /// <returns>The server adapter</returns>
        protected override AzureSqlDatabaseTransparentDataEncryptionArmAdapter InitModelAdapter(IAzureSubscription subscription)
        {
            return new AzureSqlDatabaseTransparentDataEncryptionArmAdapter(DefaultProfile.DefaultContext);
        }

        /// <summary>
        /// Returns null in default implementation
        /// </summary>
        /// <returns>null, since the certificate does not exist</returns>
        protected override IEnumerable<AzureRmSqlManagedInstanceTransparentDataEncryptionProtectorModel> GetEntity()
        {
            return null;
        }

        /// <summary>
        /// Returns input model for default implementation
        /// </summary>
        /// <param name="model"> Model to send to the update API</param>
        /// <returns>The model to send to the update</returns>
        protected override IEnumerable<AzureRmSqlManagedInstanceTransparentDataEncryptionProtectorModel> 
            ApplyUserInputToModel(IEnumerable<AzureRmSqlManagedInstanceTransparentDataEncryptionProtectorModel> model)
        {
            return model;
        }

        /// <summary>
        /// Returns input model for default implementation
        /// </summary>
        /// <param name="entity">The update parameters</param>
        /// <returns>The response object from the service</returns>
        protected override IEnumerable<AzureRmSqlManagedInstanceTransparentDataEncryptionProtectorModel> 
            PersistChanges(IEnumerable<AzureRmSqlManagedInstanceTransparentDataEncryptionProtectorModel> entity)
        {
            return entity;
        }
    }
}