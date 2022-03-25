param (
    [Parameter(Mandatory=$true)]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    [String]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    $RulesFilePath,
    [Parameter(Mandatory=$false)]
    [string]$ActionGroupName="AutoGenAG",
    [Parameter(Mandatory=$false)]
    [switch]$SkipActionGroupCreation,
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

function GetEmailList
{
    Write-Output "Getting emails from $RulesFilePath file"
    $json = Get-Content $RulesFilePath | Out-String | ConvertFrom-Json
    $emails = $json.emailTo -split ", "
    Set-Variable -Name "EmailList" -Value $emails -Scope 1
}

function CreateActionGroup 
{
    Write-Host "Creating action group"
    GetEmailList
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
    new-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile .\ActionGroup\ActionGroup.Template.json -TemplateParameterObject @{actionGroupName=$ActionGroupName; actionGroupShortName=$ActionGroupName.ToLower(); emailReceivers=$emailReceivers;}
    Write-Host "Action group created successfully" -ForegroundColor Green
}

function CreateAlerts
{
    Write-Output "Parsing the $RulesFilePath for rules."
    $json = Get-Content $RulesFilePath | Out-String | ConvertFrom-Json
    $deploymentValidation = $json.deployment_validation

    $alertName1 = $json.ApplicationName + "DeploymentValidationPassed"
    $alertName2 = $json.ApplicationName + "DeploymentValidationFailed"
    $applicationInsightsName = $json.ApplicationName + "Insights"

    Write-Output "Creating deployment alerts"
    $alertSeverity1 = 3
    $alertSeverity2 = 2
    $isEnabled = $true
    $query = 'customEvents
    | where customDimensions["Version"] == (tostring(toscalar(customEvents
        | where customDimensions  has "version"
        | top 1 by timestamp
        | project customDimensions["Version"])))'
    $operator2 = "LessThan"
    $operator1 = "GreaterThanOrEqual"
    $threshold = "5"
    $timeAggregation = "Count"

    New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile .\ARM_ALERT.json `
        -TemplateParameterObject @{
            alertName=$alertName1
            location="CentralIndia"
            isEnabled=$isEnabled
            alertSeverity=$alertSeverity1
            subscriptionId=$SubscriptionId
            resourceGroupName=$ResourceGroupName
            applicationInsightsName=$applicationInsightsName
            query=$query
            operator=$operator1
            threshold=$threshold
            timeAggregation=$timeAggregation
            actionGroupName=$actionGroupName
        }

        New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile .\ARM_ALERT.json `
        -TemplateParameterObject @{
            alertName=$alertName2
            location="CentralIndia"
            isEnabled=$isEnabled
            alertSeverity=$alertSeverity2
            subscriptionId=$SubscriptionId
            resourceGroupName=$ResourceGroupName
            applicationInsightsName=$applicationInsightsName
            query=$query
            operator=$operator2
            threshold=$threshold
            timeAggregation=$timeAggregation
            actionGroupName=$actionGroupName
        }

        Write-Host "Alerts created successfully." -ForegroundColor Green
}

function main
{
    LoginToSubscription

    Write-Host "Creating application insights resource named VotingAppInsights"
    Start-Sleep 5

    if (!$SkipActionGroupCreation)
    {
        CreateActionGroup
    }
    if (!$SkipAlertCreation)
    {
        CreateAlerts
    }
}

main;
