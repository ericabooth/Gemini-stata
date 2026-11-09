# gemini-stata

Use Google's Gemini AI directly from the Stata command line to support research, coding, and data tasks via Gemini CLI (requires user to have a Google Account with Gemini activated (paid or not, Pro account not required)

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

Install from GitHub in Stata:

```stata
net install gemini, from("https://raw.githubusercontent.com/ericabooth/Gemini-stata/main/") replace force
discard
which gemini
help gemini
```

The repository ships `gemini.pkg` and `stata.toc`, so the command and its help
file arrive in one call. To install by hand instead, copy `gemini.ado` and
`gemini.sthlp` into the `g/` folder of your PLUS directory (type `sysdir` in
Stata to see where PLUS is), or simply use `net install` as above.

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

## What gemini does on your machine

- **The query is passed as typed.** On macOS and Linux it goes to the CLI in
  single quotes, so `$5`, `$HOME`, `$(...)` and backticks are not expanded or
  run by the shell. On Windows, double quotes in the query become single quotes.
- **`--yolo` is on by default.** The CLI is run as `gemini --yolo -p ...`, which
  lets it approve its own tool actions (web search and page fetches, but also
  shell commands and file writes in Stata's working folder). Add the `noyolo`
  option to turn this off.
- **Data files.** With `csv` or `json`, Gemini is asked to wrap the table in
  `BEGIN_DATA` / `END_DATA` markers. The block is saved as `gemini_data.csv` or
  `gemini_data.json` in the working folder (replacing a file of that name) and
  imported with `encoding("utf-8")` and `bindquote(strict)`. A plain query
  writes no files.
- **JSON** is converted by Stata's own Python (`python query`), using only the
  standard library; pandas is not needed.
- **Errors.** A missing or failing CLI (for example, not signed in) stops with
  `r(498)` and shows the CLI's full error output. A `csv`/`json` request that
  returns no data block stops with `r(459)` and leaves the data in memory as
  they were.

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

## Alternative 'stata_ai': Sandboxed Local LLM (macOS)

For users who require total data privacy, you can run a local LLM using **Ollama**. This allows you to generate Stata code from your terminal.

### Installation & Setup
Copy and paste the following into your Terminal:

```bash
# Install Ollama runner
brew install ollama

# Start Ollama in the background
nohup ollama serve > /dev/null 2>&1 &

# Pull Gemma 3 (12B) - Top local performer for Stata code
ollama pull gemma3:12b

# Create a 'stata_ai' alias for precision
alias stata_ai='ollama run gemma3:12b "Act as an expert Stata programmer. Provide only the code, no explanation unless asked. My query: "'
```
Run `stata_ai "query here"` from the terminal. Stata's `shell` does not load
terminal aliases, so from Stata call Ollama directly:
`!ollama run gemma3:12b "query here"`.

**Why this setup?**
1. **Gemma 3:** High-accuracy for Stata tasks (77.8%+), outperforming Llama 3 for specific syntax.
2. **Privacy:** Entirely local; your sensitive evaluation data never leaves your computer.

## Changelog
- **2.3.4 (2026-11-09)**: The query reaches the CLI exactly as typed (`$`, `$( )` and backticks are no longer expanded or run by the shell), and `path()` may contain spaces. CLI failures exit with `r(498)`; a `csv`/`json` response without data exits with `r(459)`. Fenced or inline data blocks are read; imports use UTF-8 and `bindquote(strict)`; `json` uses Stata's Python without pandas. Plain queries no longer write `gemini_data.*`, and `json` no longer writes helper files to the working folder. New `noyolo` option.
- **2.3.3 (2026-11-09)**: Answers are read and printed by Mata, so lines with quote characters such as `` `"text"' `` no longer stop the command with `r(132)`. The CLI's stderr is captured separately and only it is noise-filtered, so answer lines such as "Note that ..." are no longer dropped. When the CLI returns no answer, its full stderr is shown.

## Author
**Eric A. Booth**  
Sr Researcher, Texas 2036 ([texas2036.org](https://texas2036.org/))  
eric.a.booth@gmail.com  
GitHub: [ericabooth/Gemini-stata](https://github.com/ericabooth/Gemini-stata)
