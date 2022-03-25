param (
    [Parameter(Mandatory=$true)]
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
    [String[]]$EmailList,
    [Parameter(Mandatory=$false)]
    [switch]$SkipAlertCreation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

function CreateAlert
{
    Write-Host "Creating  alert"
    $alertName = "AutomatedAlert"
    $alertDescription = "Automated alert created from script"
    $alertSeverity = 3
    $isEnabled = $true
    $applicationInsightsName = "VotingAppInsights"
    $query = 'customEvents
    | where customDimensions["Version"] == (tostring(toscalar(customEvents
        | where customDimensions  has "version"
        | top 1 by timestamp
        | project customDimensions["Version"])))'
    $operator = "LessThan"
    $threshold = "200"
    $timeAggregation = "Count"
    $actionGroupName = "AutoActionGroup"

    new-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile .\ARM_ALERT.json `
        -TemplateParameterObject @{
            alertName=$alertName
            location="CentralIndia"
            alertDescription=$alertDescription
            isEnabled=$isEnabled
            alertSeverity=$alertSeverity
            subscriptionId=$SubscriptionId
            resourceGroupName=$ResourceGroupName
            applicationInsightsName=$applicationInsightsName
            query=$query
            operator=$operator
            threshold=$threshold
            timeAggregation=$timeAggregation
            actionGroupName=$actionGroupName
        }
}

function main
{
    LoginToSubscription

    Write-Host "$SkipActionGroupCreation"
    if (!$SkipActionGroupCreation)
    {
        Write-Host $"$SkipActionGroup, " + (!$SkipActionGroup).ToString()
        CreateActionGroup
    }
    if (!$SkipAlertCreation)
    {
        CreateAlert    
    }
}

main





