param (
    [Parameter()]
    $SubscriptionId,
    [Parameter()]
    $ResourceGroupName,
    [Parameter()]
    $ApplicationInsightsName,
    [Parameter()]
    $RulesFilePath,
    [Parameter()]
    $AlertLocation,
    [Parameter()]
    $DeployVersion
)


# Read Rules.json
    # Read emails - generate object for emailReceivers (array) in ActionGroups
                # Eg. $jsonRequest = @(
                #      @{
                #             name = 'abc'
                #             emailAddress = 'xyz@gmail.com'
                #             useCommonAlertSchema = $true
                #         }
                #     ) 
        # Create action group using ARM_ACTION (autogenerate required names)
                    # Example call to ARM Templates
                    # new-AzResourceGroupDeployment -TemplateFile .\ARM_ACTION_GRP.json -TemplateParameterObject @{actionGroupName='testArm'; actionGroupShortName='abc12311'; emailReceivers=$jsonRequest;}
    # For each rules object
        # Create query for ARM_ALERT (make required changes in the ARM template)
        # Call ARM_ALERT (autogenerate required names and pass required params)











