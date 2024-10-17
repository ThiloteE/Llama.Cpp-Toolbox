# RestCalls version
$global:RestCalls_Ver = 0.1.0

# RestAPI Functions

# Server options (more options at llama.cpp)
# llama-server 8080 -np 2 --slots --props --slot-save-path \logs\inference\saved-chats
# When starting a server set the number of paralel slots you wish to have available to use, -np 2
# Enable the slots endpoint, --slots 
# Enable changing properties, --props
# Enable the path to save,  --slot-save-path \logs\inference\saved-chats TODO: Make this a default setting
# Require an api key, --api-key YOUR_KEY
# Set an alias for the model,  --alias model_nickname
# When sending requests "cache_prompt = true" will set the cache to persist between messages on the slot.


<# Example chatCompletion.
# Start a server
# Load related functions into memory.
# Assign variables for the conversation.
$global:path = "C:\Users\%USERNAME%\LlamaCpp-Toolbox" # Adjust your path to the toolbox
$AssistantName = "" # Set the name for the assistant.
$UserName = "" # Set the username
$Role = "user" # In this case the my role is user because of the model I use.
$sessionName = "$AssistantName" # Choose your save file name.
$saveFilePath = "$path\logs\inference\saved-chats\$sessionName.json" # Where to save the chat session.
$Port = 8080 # The port used by the server
$Slot = 0 # The slot to use default is 0 if no other slots were created with the server.

#WIP# Import system prompt entry in the new messageArray. WIP
#WIP#$ImportFilePath = "$path\logs\inference\system-prompt\$AssistantName\system-prompt.json"
#WIP#$messageArray = Import-SystemPrompt -ImportFilePath $importFilePath

# When this is outdated it will be replaced with Import-SystemPrompt.
$SystemPrompt = "I am a helpful AI. I know the date and time as well as the name of the individual who sent the message. All of that information is provided automatically. In messages I send, I don't need to write the date, time or my name unless requested or it is required."

# Define the first message array correctly, as needed by the model.
# The function InitializeChat will create an array for a model that has roles of user, assistant, system.
# Example array for a system prompt.
$messageArray = @(
    @{
        "role" = "system"
        "content" = "$SystemPrompt"
    }
)

# Ensure you load an existing chat or start a new one.
# For a new chat, don't include the argument for a save file path.
# If you use a model without a system prompt capability don't include the argument for a system prompt.
$messageArray = InitializeChat -SystemPrompt $SystemPrompt -saveFilePath $saveFilePath 

# You may import compatible existing messages from another file at any time after initializing the chat.
# $ImportFilePath = "$path\logs\inference\saved-chats\filename.json"
# $messageArray = Import-Messages -ExistingArray $messageArray -ImportFilePath $ImportFilePath

# Set the prompt to send in the next message.
$Prompt = "I just loaded you from a save file. What do you remember at this moment?"

# Send, recieve and save...
# Get the messageArray and send it to the server with the new message and the path to save the conversation.
$messageArray = SendMessage -Port $Port -Slot $Slot -MessageArray $messageArray -Prompt $Prompt -saveFilePath $saveFilePath

# Repeat the last two items to send/recieve & save new messages.
#>

# Example usage: $completionResponse = Get-ChatCompletion -Port 8080 -Slot 0 -Prompt "The System Prompt" -Message "The Json formatted Messages" -NPredictTokens -1 -CachePrompt $true -API_Key "KEY"
function Get-ChatCompletion {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Port,

        [Parameter(Mandatory=$true)]
        [int]$Slot,
        
        [Parameter(Mandatory=$true)]
        [array]$Messages,
        
        [Parameter(Mandatory=$false)]
        [string]$API_Key,

        [Parameter(Mandatory=$true)]
        [int]$NPredictTokens,
        
        [Parameter(Mandatory=$true)]
        [bool]$CachePrompt,
        
        [Parameter(Mandatory=$false)]
        [bool]$Stream = $false
    )
    $baseUrl = "http://localhost:$Port"
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "$API_Key"
    }
    
    $body = @{
        id_slot = $Slot
        messages = $Messages
        n_predict = $NPredictTokens
        temperature = 0.1 # Put this into param when ready for use.
        seed = 42 # Put this into param when ready for use.
        cache_prompt = $CachePrompt
        stream = $Stream
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/v1/chat/completions" -Method Post -Headers $headers -Body $body
        #Write-Host $response
        return $response
    }
    catch {
        Write-Error "Error making request: $_"
        return $null
    }
}

# Send and save each message
# Adjust message format as needed. I have included timestamp, name of sender followed by their prompt.
function SendMessage{
    param (
        
        [Parameter(Mandatory=$true)]
        [string]$Port,
        
        [Parameter(Mandatory=$false)]
        [string]$Slot,

        [Parameter(Mandatory=$true)]
        [array]$MessageArray,
        
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [Parameter(Mandatory=$true)]
        [string]$saveFilePath

    )
    $timestamp = Get-Date -Format "yyyy/MM/dd-HH:mm:ss"
    # Insert the new message into the array.
    $messageArray += @{
            "role" = "$Role"
            "content" = "$timestamp $UserName`: $Prompt"
        }

    # Call the function with the message array add each message and response
    $chatResponse = Get-ChatCompletion -Port $Port -Slot $Slot -Messages $messageArray -NPredictTokens -1 -CachePrompt $true
    $responseContent = $chatResponse.choices[0].message.content
    Write-Host "$responseContent"

    # Insert the assistant response into the array.
    $messageArray += @{
            "role" = "assistant"
            "content" = "$timestamp $AssistantName`: $responseContent"
        }

    # After each message exchange, save the updated message array
    Save-MessageArray -MessageArray $messageArray -FilePath $saveFilePath
    
    return $messageArray
}

# Save the message array (SendMessage helper)
function Save-MessageArray {
    param (
        [Parameter(Mandatory=$true)]
        [array]$MessageArray,
        
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    $MessageArray | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath
}

# Load the message array (InitializeChat helper)
function Load-MessageArray {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    if (Test-Path $FilePath) {
        $content = Get-Content -Path $FilePath -Raw
        return ($content | ConvertFrom-Json)
    } else {
        Write-Warning "File not found. Returning empty array."
        return @()
    }
}

# Initialize a chat
# Check if there's a saved message array and load it, otherwise return the initial array.
function InitializeChat{
    param (
        [Parameter(Mandatory=$false)]
        [string]$SystemPrompt,
        [Parameter(Mandatory=$false)]
        [string]$saveFilePath
    )
    if (Test-Path $saveFilePath) {
        $messageArray = Load-MessageArray -FilePath $saveFilePath
    }
    elseif ($SystemPrompt -ne "") {
        $messageArray = @(
            @{
                "role" = "system"
                "content" = "$SystemPrompt"
            }
        )
    }
    else {
        $messageArray = @(
            @{
                "role" = "assistant"
                "content" = ""
            }
        )
    }
    return $messageArray
}


# Import existing messages from another file
# $ImportFilePath = "$path\logs\inference\saved-chats\filename.json"
# $messageArray = Import-Messages -ExistingArray $messageArray -ImportFilePath $ImportFilePath
function Import-Messages {
    param (
        [Parameter(Mandatory=$true)]
        [array]$ExistingArray,
        
        [Parameter(Mandatory=$true)]
        [string]$ImportFilePath
    )
    
    # Load the messages from the import file
    $importedMessages = Get-Content -Path $ImportFilePath | ConvertFrom-Json
    
    # Filter out any messages with role "system"
    $filteredMessages = $importedMessages | Where-Object { $_.role -ne "system" }
    
    # Append the filtered messages to the existing array
    $updatedArray = $ExistingArray + $filteredMessages
    
    return $updatedArray
}

# Import system prompt from json.
function Import-SystemPrompt {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ImportFilePath
    )
    
    try {
        # Load the content from the import file
        $importedContent = Get-Content -Path $ImportFilePath -Raw | ConvertFrom-Json

        # Initialize an empty array to hold all content
        $allContent = @()

        # Iterate through each property in the imported content
        foreach ($prop in $importedContent.PSObject.Properties) {
            $allContent += $prop.Value
        }

        # Join all content with newlines
        $combinedContent = $allContent -join "`n`n"

        # Create the system prompt entry
        $systemPromptEntry = @{
            "role" = "system"
            "content" = "$combinedContent"
        }

        return $systemPromptEntry
    }
    catch {
        Write-Error "Error importing system prompt: $_"
        return $null
    }
}


# Example usage: $completionResponse = Get-Completion -Port 8080 -Slot 0 -Prompt "Two plus two equals" -NPredictTokens 1 -CachePrompt $false
function Get-Completion {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Port,

        [Parameter(Mandatory=$true)]
        [int]$Slot,

        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [Parameter(Mandatory=$true)]
        [int]$NPredictTokens,
        
        [Parameter(Mandatory=$true)]
        [bool]$CachePrompt,
        
        [Parameter(Mandatory=$false)]
        [bool]$Stream = $false
    )
    $baseUrl = "http://localhost:$Port"
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    $body = @{
        id_slot = $Slot
        prompt = $Prompt
        n_predict = $NPredictTokens
        temperature = 0.1 # Put this into param when ready for use.
        seed = 42 # Put this into param when ready for use.
        cache_prompt = $CachePrompt
        stream = $Stream
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/completion" -Method Post -Headers $headers -Body $body
        #write-host $response
        return $response
    }
    catch {
        Write-Error "Error making request: $_"
        return $null
    }
}
#$Prompt = "PowerShell 5.1 # Multi-Server LLM Agent Framework" # The completion mode will attempt to continue any text.
#$completionResponse = Get-Completion -Port 8080 -Slot 0 -Prompt $Prompt -NPredictTokens -1 -CachePrompt $false
#$Prompt + $completionResponse[0].content


# Request "slots" status for server
# Example usage: $slotsResponse = Get-Slots -Port 8080
# Example usage: $slotsResponse[0].n_ctx
# Example usage: $slotsResponse[0].model
# Example usage: $slotsResponse[0].prompt
function Get-Slots {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Port
    )
    $baseUrl = "http://localhost:$Port"
    $slotsUrl = "$baseUrl/slots"
    $headers = @{
        Accept = "*/*"
        Host = "localhost:$Port"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $slotsUrl -Method Get -Headers $headers -ContentType "application/json"
        Write-Host ($response | ConvertTo-Json -Depth 10)
        return $response
    }
    catch {
        Write-Error "Error retrieving slots: $_"
        return $null
    }
}
#$slotsResponse = Get-Slots -Port 8080
#$slotsResponse[0].prompt

# Request "health" status for server
# Example usage: $healthResponse = Get-Health -Port 8080
# Example usage: $healthResponse[0].status
# Example usage: $healthResponse[0].error
function Get-Health {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Port
    )
    $baseUrl = "http://localhost:$Port"
    $slotsUrl = "$baseUrl/health"
    $headers = @{
        Accept = "*/*"
        Host = "localhost:$Port"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $slotsUrl -Method Get -Headers $headers -ContentType "application/json"
        Write-Host ($response | ConvertTo-Json -Depth 10)
        return $response
    }
    catch {
        Write-Error "Error retrieving health: $_"
        return $null
    }
}
#$healthResponse = Get-Health -Port 8080
#$healthResponse[0].status

# Request "props" properties of the server
# Example usage: $propsResponse = Get-Props -Port 8080
# Example usage: $propsResponse[0].system_prompt
# Example usage: $propsResponse[0].default_generation_settings # Use dot notation for specific setting as seen below.
# Example usage: $propsResponse[0].default_generation_settings.n_ctx # Use dot notation for specific setting as seen here.
# Example usage: $propsResponse[0].total_slots
# Example usage: $propsResponse[0].chat_template
function Get-Props {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Port
    )
    $baseUrl = "http://localhost:$Port"
    $slotsUrl = "$baseUrl/props"
    $headers = @{
        Accept = "*/*"
        Host = "localhost:$Port"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $slotsUrl -Method Get -Headers $headers -ContentType "application/json"
        Write-Host ($response | ConvertTo-Json -Depth 10)
        return $response
    }
    catch {
        Write-Error "Error retrieving properties: $_"
        return $null
    }
}
#$propsResponse = Get-Props -Port 8080
#$propsResponse[0].default_generation_settings.n_ctx

# Set-Props (WIP)
# Example usage: $propsResponse = Set-Props -Port 8080 -SlotId 0 -Filename "chat-1.bin"
function Set-Props {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Port,

        [Parameter(Mandatory=$true)]
        [int]$SlotId,
        
        [Parameter(Mandatory=$true)]
        [string]$Filename
    )
    $baseUrl = "http://localhost:$Port"
    $saveUrl = "$baseUrl/props/$SlotId"
    $body = @{
        filename = $Filename
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri $saveUrl -Method Post -Body $body -ContentType "application/json"
        write-host $response
        return $response
    }
    catch {
        Write-Error "Error saving properties: $_"
        return $null
    }
}

# What is this useful for? (WIP)
# Example usage: $savedKVCache = Save-KVCache -Port 8080 -SlotId 0 -Filename "KVCache.bin"
function Save-KVCache {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Port,

        [Parameter(Mandatory=$true)]
        [int]$SlotId,
        
        [Parameter(Mandatory=$true)]
        [string]$Filename
    )
    $baseUrl = "http://localhost:$Port"
    $saveUrl = "$baseUrl/slots/$SlotId`?action=save"
    $body = @{
        filename = $Filename
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri $saveUrl -Method Post -Body $body -ContentType "application/json"
        write-host $response
        return $response
    }
    catch {
        Write-Error "Error saving KVCache: $_"
        return $null
    }
}

# What is this useful for? (WIP)
# Example usage: $restoredKVCache = Restore-KVCache -Port 8080 -SlotId 0 -Filename "KVCache.bin"
function Restore-KVCache {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Port,

        [Parameter(Mandatory=$true)]
        [int]$SlotId,
        
        [Parameter(Mandatory=$true)]
        [string]$Filename
    )
    $baseUrl = "http://localhost:$Port"
    $restoreUrl = "$baseUrl/slots/$SlotId`?action=restore"
    $body = @{
        filename = $Filename
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri $restoreUrl -Method Post -Body $body -ContentType "application/json"
        write-host $response
        return $response
    }
    catch {
        Write-Error "Error restoring KVCache: $_"
        return $null
    }
}


Export-ModuleMember -Function * -Variable * -Alias *