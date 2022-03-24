param (
    [Parameter()]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    [String]$ResourceGroupName,
    [Parameter()]
    $ApplicationInsightsName,
    [Parameter()]
    $RulesFilePath,
    [Parameter()]
    $AlertLocation,
    [Parameter()]
    $DeployVersion,
    [Parameter(Mandatory=$false)]
    [switch]$SkipActionGroupCreation,
    [Parameter(Mandatory=$false)]
    [String[]]$EmailList
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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


function LoginToSubscription
{
    $connencted = $false
    try {
        if ($null -ne (Get-AzSubscription)) {
            $connencted = $true
        }
    }
    catch
    {
    }

    if (!$connencted) {
        Connect-AzAccount
    }
}

function CreateActionGroup 
{
    Write-Host "Creating action group"
    if (($null -eq $EmailList) -or ($EmailList.Count -eq 0))
    {
        Write-Error "Kindly Specify EmailList for creation of Action Group"
    }
    [hashtable[]]$emailReceivers = @()
    foreach ($emailAddr in $EmailList)
    {
        Write-Host "Adding $emailAddr to the action group"
        [hashtable]$singleEmailProp = @{
            name = $emailAddr
            emailAddress = $emailAddr
            useCommonAlertSchema = $true
        }
        $emailReceivers += $singleEmailProp
    }
    new-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile .\ActionGroup\ActionGroup.Template.json -TemplateParameterObject @{actionGroupName='AutoActionGroup'; actionGroupShortName='autoact'; emailReceivers=$emailReceivers;}
    Write-Host "Action group created successfully"
}


function main
{
    LoginToSubscription

    if ($SkipActionGroupCreation -eq $false)
    {
        CreateActionGroup
    }
}

main





