# gemini-stata

Use Google's Gemini AI directly from the Stata command line to support research, coding, and data tasks.

## Overview

`gemini` is a Stata command that wraps the official [Gemini CLI](https://github.com/google/gemini-cli). It allows you to:
- Perform live web searches for data and facts.
- Generate synthetic datasets for testing.
- Get instant help with Stata syntax and coding logic.
- Extract structured data (CSV/JSON) directly into Stata memory.

## Prerequisites

This command requires the **Gemini CLI** to be installed and authenticated on your system.

### 1. Install Node.js
- **macOS**: `brew install node`
- **Windows**: Download the installer from [nodejs.org](https://nodejs.org/).
- **Linux**: Use your package manager, e.g., `sudo apt install nodejs npm`.

### 2. Install Gemini CLI
Run the following in your terminal:
```bash
npm install -g @google/gemini-cli
```

### 3. Authenticate
Run `gemini` in your terminal and follow the login prompts to authorize your Google account.

## Installation in Stata

Copy `gemini.ado` and `gemini.sthlp` to your Stata PLUS directory (usually `~/Documents/Stata/ado/plus/g/` or equivalent). Or install via GitHub (if hosted):

```stata
net install gemini, from("https://raw.githubusercontent.com/ericbooth/Gemini-stata/master/")
```

## Usage

### Basic Query
```stata
gemini "What is the capital of France?"
```

### Data Extraction to Stata
```stata
gemini "List the top 5 largest cities in Texas with their 2020 population", csv clear
```

### Stata Help
```stata
gemini "How do I use the margins command after a probit regression?"
```

## Troubleshooting

### "gemini" command not found
If Stata can't find the executable, find its path in your terminal:
- **Mac/Linux**: `which gemini`
- **Windows**: `where gemini`

Then specify the path in Stata:
```stata
gemini "test", path("/usr/local/bin/gemini")
```

### Permission Errors
On Mac/Linux, if `npm install` fails, avoid `sudo` by using a version manager like `nvm` or by changing your npm global directory.

### Windows Execution Policy
If PowerShell blocks the script, run this as Administrator:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Author
**Eric A. Booth**  
eric.a.booth@gmail.com
