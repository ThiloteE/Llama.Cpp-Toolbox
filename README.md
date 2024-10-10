**Simple installation, just download "Llama.Cpp-Toolbox.ps1" to the directory you want to install in and run the script.**

# Llama.Cpp-Toolbox
Llama.Cpp-Toolbox is a PowerShell GUI interface, designed to streamline your workflow when working with models using llama.cpp. 

The main window includes functionality allowing you to clone models using git and keep them updated, convert and quantize them, inspect gguf metadata, as well as aditional functionality.  

![image](https://github.com/user-attachments/assets/ab3df6c5-11a7-4483-9264-5e9d1b3e9ba9)



Here's an overview of its functionality:

**Config**
  - This menu item will open the config form that will allow you to manage Toolbox options and llama.cpp branches.
  - Select the release or dev branch you wish to build, all package requirements will be set as needed.
  - You may edit and show or hide options for the task list menu.

 **Process Manager**
  - This menu item will open the Process Manager that will allow you to manage running models.
 
 **Update llama.cpp**
   - This menu item allows you to use the latest git pull of llama.cpp from its GitHub repository. It will prompt you with a confirmation message before proceeding. Upon completion, it will not update the toolbox GUI.
   - The package requirements will be updated ensuring you have the latest packages for your build.

 **Update Toolbox**
   - This menu item allows you to update the LlamaCpp-Toolbox itself from its GitHub repository. It will prompt you with a confirmation message before proceeding. Upon completion, it will restart the toolbox GUI as needed, for any changes to take effect.

 **Update/Rebuild Button**
   - Update, This button checks if there are any updates available for the selected model (from the first dropdown). If an update is found, git will pull the changes.
   - Update, If there is nothing selected this button will detect LLMs you may have added to the directory manually then put them into the list.
   - Rebuild, When llama.cpp needs to be built this button will allow you to do that.

 **Clone Button**
   - Use this button to git clone a model from a given URL into the llama.cpp models directory. After cloning, it will list all available models in the dropdown menu.

**Process Button**
   - This is the main action button that triggers various tasks based on the selected model (from the first dropdown) and task (from the second dropdown). Upon execution, it will attempt to complete the action and display the information in the window.

 **Task List**
  - This is the list of functions to execute based on the selected model (from the first dropdown) and task (from the second dropdown). Upon execution, it will display the information in the window.
  - Include any options llama.cpp supports.

```Symlink```
   - This task creates a symlink for the selected model in the directory specified by the user in the config file (symlinkdir). It requires administrative privileges and displays status information during the creation process.
   - If you choose not to provide the admin rights at the prompt you will still recieve the command to be used via the windows Command Prompt in the directory you wish to create the symlink.

```Model List```
   - This task lists all available models in your local directory.
   - Copy and paste the pre-formatted text to compare them all in the [open-llm-leaderboard](https://huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard).

```llama-cli```
  - Run the selected model from the command line interface.
  - Set your own system prompt by editing the task in the list before you click process.

```llama-server```
  - Start your own llama server for access via the OpenAI-API
  - This will also open the default browser to allow you to use the llama.cpp web based chat interface.
  - If you want to set a port, add an api key or other option just edit the command. To save it add it to the config.  "llama-server 8081 --api-key KEY --alias local-llama"

```Convert```
   - These scripts attempt to convert the selected model from one format (e.g., .bin or .safetensors) to another (.gguf). It utilizes the selected conversion script from the second dropdown menu and displays progress information during the conversion process.

```Quantize```
   - This function quantizes the selected model to reduce its memory footprint while maintaining performance. It uses the llama-quantize.exe utility from the llama.cpp framework, which is included in the tool's virtual environment. The process involves converting the model into a new format with varying levels of compression and then displaying status information during the quantization steps.
  - Custom options may be added to the config, certain usefull items have been predefined.

```gguf_dump```
  - This task allows you to retrieve metadata directly from any gguf.
  - Custom calls may be added to the config.

## Citations

If you utilize this repository, in a downstream project, please consider citing it with:
```
@misc{Llama.Cpp-Toolbox,
  author = {Clayton Williams},
  title = {Llama.Cpp-Toolbox: Graphic user interface enabling ease of use of select Llama.cpp functionality},
  year = {2024},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/3Simplex/Llama.Cpp-Toolbox}},
},
@misc{llama.cpp,
  author = {Georgi Gerganov, https://github.com/ggerganov/llama.cpp/graphs/contributors},
  title = {llama.cpp: Inference of Meta's LLaMA model (and others) in pure C/C++},
  year = {2023},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/ggerganov/llama.cpp}},
},
@misc{gpt4all,
  author = {Yuvanesh Anand and Zach Nussbaum and Brandon Duderstadt and Benjamin Schmidt and Andriy Mulyar},
  title = {GPT4All: Training an Assistant-style Chatbot with Large Scale Data Distillation from GPT-3.5-Turbo},
  year = {2023},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/nomic-ai/gpt4all}},
}
