param( 
    [Parameter(Mandatory=$true)] $JSONFile,
    [switch]$Undo
)

function CheckGroupExist() {
    param( [Parameter(Mandatory=$true)] $groupObject)
    $name = $groupObject.name

    try {
        $Group = Get-ADGroup -Filter { Name -eq $name } -ErrorAction Stop
        Write-Output "Group '$name' exists in Active Directory."
    } catch {
        CreateADGroup $groupObject
    }
}

function CreateADGroup() {
    param( [Parameter(Mandatory=$true)] $groupObject)

    $name = $groupObject.name
    New-ADGroup -name $name -GroupScope Global
}

function RemoveADGroup(){
    param( [Parameter(Mandatory=$true)] $groupObject )

    $name = $groupObject.name
    Remove-ADGroup -Identity $name -Confirm:$False
}

function CreateADUser(){
    param( [Parameter(Mandatory=$true)] $userObject)

    #Pull out the name from Json object
    $name = $userObject.name
    $password = $userObject.password

    #Generate aa "first initial, last name" structure for username
    $firstname, $lastname = $name.Split(" ")
    $username = ($firstname[0] + $lastname).ToLower()
    $samAccountName = $username
    $principalname = $username

    #Create Ad user object
    New-ADUser -Name "$name" -GivenName $firstname -Surname $lastname -SamAccountName $samAccountName -UserPrincipalName $principalname@$Global:Domain -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -PassThru | Enable-ADAccount 

    foreach ($group_name in $userObject.groups) {
        try{
            Get-ADGroup -Identity "$group_name"
            Add-ADGroupMember -Identity $group_name -Members $username
            echo $username
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
        {
            Write-Warning "User $name NOT added to group $group_name because it does not exist "
        }
    }
}

function RemoveADUser(){
    param( [Parameter(Mandatory=$true)] $userObject )

    $name = $userObject.name
    $firstname, $lastname = $name.Split(" ")
    $username = ($firstname[0] + $lastname).ToLower()
    $samAccountName = $username
    Remove-ADUser -Identity $samAccountName -Confirm:$False
}

#disable password policy to allow weak password user
function WeakenPasswordPolicy() {
    secedit /export /cfg C:\Windows\Tasks\secpol.cfg
    (Get-Content C:\Windows\Tasks\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0").replace("MinimumPasswordLength = 7", "MinimumPasswordLength = 1") | Out-File C:\Windows\Tasks\secpol.cfg
    secedit /configure /db c:\windows\security\local.sdb /cfg C:\Windows\Tasks\secpol.cfg /areas SECURITYPOLICY
    rm -force C:\Windows\Tasks\secpol.cfg -confirm:$false
}

function StrengthenPasswordPolicy() {
    secedit /export /cfg C:\Windows\Tasks\secpol.cfg
    (Get-Content C:\Windows\Tasks\secpol.cfg).replace("PasswordComplexity = 0", "PasswordComplexity = 1").replace("MinimumPasswordLength = 1", "MinimumPasswordLength = 7") | Out-File C:\Windows\Tasks\secpol.cfg
    secedit /configure /db c:\windows\security\local.sdb /cfg C:\Windows\Tasks\secpol.cfg /areas SECURITYPOLICY
    rm -force C:\Windows\Tasks\secpol.cfg -confirm:$false
}

$json = ( Get-Content $JSONFile | ConvertFrom-Json)
$Global:Domain = $json.domain

if ( -not $Undo) {
    WeakenPasswordPolicy

    foreach ($group in $json.groups){
        CreateADGroup $group
    }

    foreach( $user in $json.users) {
        CreateADUser $user
    }
}else{
    StrengthenPasswordPolicy

    foreach ($group in $json.groups){
        RemoveADGroup $group
    }

    foreach( $user in $json.users) {
        RemoveADUser $user
    }
}
