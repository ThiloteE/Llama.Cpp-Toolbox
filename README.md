# Llama.Cpp-Toolbox
Llama.Cpp-Toolbox is a PowerShell GUI interface, designed to streamline your workflow when working with models using llama.cpp. 

The main window includes functionality allowing you to clone models using git and keep them updated, convert and quantize them, inspect gguf metadata, as well as aditional functionality.  

Here's an overview of its functionality:

 **Update Toolbox**
   - This button allows you to update the LlamaCpp-Toolbox itself from its GitHub repository. It will prompt you with a confirmation message before proceeding. Upon completion, it will restart the toolbox GUI as needed, for any changes to take effect.

 **Update llama.cpp**
   - This button allows you to use the latest git pull of llama.cpp from its GitHub repository. It will prompt you with a confirmation message before proceeding. Upon completion, it will not update the toolbox GUI.

**Process Button**
   - This is the main action button that triggers various tasks based on the selected model (from the first dropdown) and function (from the second dropdown). Upon execution, it will attempt to complete the action and display the information in the window.

 **Function List**
   - This is the list of functions to execute based on the selected model (from the first dropdown) and script (from the second dropdown). Upon execution, it will display the information in the window.

 **Clone Model**
   - Use this button to git clone a model from a given URL into the llama.cpp models directory. After cloning, it will list all available models in the dropdown menu.

 **Check For Updates**
   - this button checks if there are any updates available for the selected model (from the first dropdown). If an update is found, a confirmation dialog appears before updating the model and restarting the toolbox GUI.

 **Quantize Model**
   - This function quantizes the selected model to reduce its memory footprint while maintaining performance. It uses the llama-quantize.exe utility from the llama.cpp framework, which is included in the tool's virtual environment. The process involves converting the model into a new format with varying levels of compression and then displaying status information during the quantization steps.

 **Convert Scripts**
   - These scripts attempt to convert the selected model from one format (e.g., .bin or .safetensors) to another (.gguf). It utilizes the selected conversion script from the second dropdown menu and displays progress information during the conversion process.

 **Model List**
   - This function lists all available models in your local directory, allowing you to easily select a model for further action.

 **Symlink Model**
   - this button creates a symlink for the selected model in the directory specified by the user in the config file (symlinkdir). It requires administrative privileges and displays status information during the creation process.

 **Help**
   - This menu provides access to additional resources, such as documentation or tutorials related to using LlamaCpp-Toolbox.

 **About**
    - clicking this option opens a dialog box displaying version information, authorship details, and any other relevant details about the tool.

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
