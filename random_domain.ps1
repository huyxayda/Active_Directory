param( [Parameter(Mandatory=$true)] $OutputJSONFile )

$group_names = [System.Collections.ArrayList](Get-Content "group_names.txt")
$first_names = [System.Collections.ArrayList](Get-Content "first_names.txt")
$last_names = [System.Collections.ArrayList](Get-Content "last_names.txt")
$passwords = [System.Collections.ArrayList](Get-Content "passwords.txt")

$UserCount = 50
$GroupCount = 10

$groups = @()
$users = @()

for ( $i = 1; $i -le $GroupCount; $i++ ){
    $group_name = (Get-Random -InputObject $group_names)
    $group = @{ "name" = "$group_name" }
    $groups += $group
    $group_names.Remove($group_name)
}

for ( $i = 1; $i -le $UserCount; $i++ ){
    $first_name = (Get-Random -InputObject $first_names)
    $last_name = (Get-Random -InputObject $last_names)
    $password = (Get-Random -InputObject $passwords)
    $user_groups = @()

    #random number of groups this user will join
    #generate number of groups for this user
    $groups_amount = (Get-Random -Minimum 1 -Maximum 4)
    
    #generate the IDs of groups in $groups array
    $IDs_groups = @()
    while ($IDs_groups.Count -lt $groups_amount) {
        # Generate a random number between 0 and 10
        $random_ID = Get-Random -Minimum 0 -Maximum $GroupCount
    
        # Add the number to the array only if it's not already present
        if (-not $IDs_groups.Contains($random_ID)) {
            $IDs_groups += $random_ID
        }
    }
    
    foreach ($Id_group in $IDs_groups) {
        $user_groups += $groups[$Id_group].name
    }
    
    $new_user = @{ `
        "name"="$first_name $last_name"
        "password"="$password"
        # "groups" = (Get-Random -InputObject $groups).name
        "groups" = $user_groups | ConvertTo-Json
        }


    $users += $new_user 

    $first_names.Remove($first_name)
    $last_names.Remove($last_name)
    $passwords.Remove($password)
}

ConvertTo-Json -InputObject @{ 
    "domain"= "homelab.local"
    "groups"=$groups
    "users"=$users 
} | Out-File $OutputJSONFile 