{smcl}
{* *! version 2.3.2  27apr2026}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "gemini##syntax"}{...}
{viewerjumpto "Description" "gemini##description"}{...}
{viewerjumpto "Options" "gemini##options"}{...}
{viewerjumpto "Examples" "gemini##examples"}{...}
{viewerjumpto "Installation Guide" "gemini##installation"}{...}
{viewerjumpto "Troubleshooting" "gemini##troubleshooting"}{...}

{title:Title}

{phang}
{bf:gemini} {hline 2} Use Gemini AI directly from the Stata command line to support research, coding, and data tasks.

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{bf:gemini} {it:query} [{cmd:,} {it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt csv}}Format results as a CSV table and import into Stata memory.{p_end}
{synopt :{opt json}}Format results as JSON and import into Stata memory (requires Python).{p_end}
{synopt :{opt clear}}Required if {cmd:csv} or {cmd:json} is used and data is already in memory.{p_end}
{synopt :{opt path(string)}}Specify the absolute path to the gemini executable.{p_end}
{synopt :{opt model(string)}}Specify the Gemini model (e.g., {cmd:gemini-1.5-flash}).{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:gemini} integrates the Gemini CLI with Stata. It allows you to perform live web searches, 
generate synthetic datasets, get coding assistance, and extract structured data directly into Stata 
using Google's Gemini models. This command requires the {cmd:@google/gemini-cli} to be installed 
on your system.

{marker options}{...}
{title:Options}

{phang}
{opt csv}: Instructs Gemini to return data in CSV format, which is then automatically imported into Stata.

{phang}
{opt json}: Instructs Gemini to return data in JSON format. This requires Python with the {cmd:pandas} library installed to convert the data for Stata import.

{phang}
{opt clear}: Standard Stata option to clear existing data from memory before importing new results.

{phang}
{opt path(string)}: Use this if the command cannot find your {cmd:gemini} installation. Provide the full path (e.g., {cmd:/usr/local/bin/gemini} or {cmd:C:\Users\Name\AppData\Roaming\npm\gemini.cmd}).

{phang}
{opt model(string)}: Specify the model to use. Common options include {cmd:gemini-1.5-flash} (fast/cheap) and {cmd:gemini-1.5-pro} (complex tasks).

{marker examples}{...}
{title:Examples}

{dlgtab:1. General Research}
{phang2}{cmd:. gemini "What are the current top 5 largest cities in Texas by population?"}{p_end}

{dlgtab:2. Data Extraction}
{phang2}{cmd:. gemini "List the top 5 largest cities in Texas with their 2020 and 2024 estimated population", csv clear}{p_end}

{dlgtab:3. Synthetic Data}
{phang2}{cmd:. gemini "Generate a synthetic dataset of 100 observations with 'age', 'income', and 'education' (HS, College, Grad)", csv clear}{p_end}

{dlgtab:4. Stata Coding Help}
{phang2}{cmd:. gemini "How do I use the -margins- command after a probit regression with an interaction term?"}{p_end}

{marker installation}{...}
{title:Installation Guide}

{pstd}This command is a wrapper for the {bf:Gemini CLI}. You MUST install the CLI first.{p_end}

{dlgtab:Step 1: Install Node.js}
{pstd}{bf:macOS}: Install via Homebrew: {cmd:brew install node}{p_end}
{pstd}{bf:Windows}: Download the installer from {browse "https://nodejs.org/"} (LTS version recommended).{p_end}
{pstd}{bf:Linux (Ubuntu/Debian)}: {cmd:sudo apt update && sudo apt install nodejs npm}{p_end}

{dlgtab:Step 2: Install Gemini CLI}
{pstd}Open your terminal (Terminal on Mac/Linux, PowerShell on Windows) and run:{p_end}
{pmore}{cmd:npm install -g @google/gemini-cli}{p_end}

{dlgtab:Step 3: Authentication}
{pstd}In your terminal, run:{p_end}
{pmore}{cmd:gemini}{p_end}
{pstd}Follow the prompts to log in to your Google account and authorize the CLI.{p_end}

{marker troubleshooting}{...}
{title:Troubleshooting}

{phang}{bf:Command not found in Stata}{p_end}
{pstd}Stata's {cmd:shell} environment may have a different PATH than your terminal. 
Run {cmd:which gemini} (Mac/Linux) or {cmd:where gemini} (Windows) in your terminal to find the path, then use the {cmd:path()} option in Stata:{p_end}
{pmore}{cmd:gemini "test", path("/usr/local/bin/gemini")}{p_end}

{phang}{bf:Permission Errors (Mac/Linux)}{p_end}
{pstd}If {cmd:npm install} fails, you may need to use {cmd:sudo} or fix your npm permissions. 
Using a version manager like {cmd:nvm} is recommended to avoid permission issues.{p_end}

{phang}{bf:Execution Policy (Windows)}{p_end}
{pstd}If PowerShell blocks the script, run PowerShell as Administrator and execute:{p_end}
{pmore}{cmd:Set-ExecutionPolicy RemoteSigned -Scope CurrentUser}{p_end}

{phang}{bf:JSON Import Fails}{p_end}
{pstd}Ensure Python is installed and accessible to Stata ({cmd:python query}). 
Install pandas: {cmd:pip install pandas}.{p_end}

{title:Author}
{pstd}Eric A. Booth{p_end}
{pstd}eric.a.booth@gmail.com{p_end}
