{smcl}
{* *! version 2.3.4  09nov2026}{...}
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
{synopt :{opt json}}Format results as JSON and import into Stata memory (uses Stata's Python).{p_end}
{synopt :{opt clear}}Required if {cmd:csv} or {cmd:json} is used and data is already in memory.{p_end}
{synopt :{opt path(string)}}Specify the absolute path to the gemini executable.{p_end}
{synopt :{opt model(string)}}Specify the Gemini model (e.g., {cmd:gemini-2.5-flash}).{p_end}
{synopt :{opt noyolo}}Do not pass {cmd:--yolo} to the CLI (see below).{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:gemini} integrates the Gemini CLI with Stata. It allows you to perform live web searches, 
generate synthetic datasets, get coding assistance, and extract structured data directly into Stata 
using Google's Gemini models. This command requires the {cmd:@google/gemini-cli} to be installed 
on your system.

{pstd}
The answer is printed exactly as the CLI returns it: SMCL is not interpreted, and quotes,
apostrophes and backticks are shown as is. Lines between {cmd:BEGIN_DATA} and {cmd:END_DATA}
are used as the data instead of being printed (see {it:Data files} below).
The CLI's error stream is read separately; routine CLI notices (retry messages, stack
frames, color-support warnings) are hidden from it. When the CLI returns no answer at all,
its whole error stream is shown so you can see why.

{pstd}
The query is sent to the CLI exactly as typed. On macOS and Linux it is passed inside single
quotes, so text such as {cmd:$5}, {cmd:$HOME} or {cmd:$(...)} reaches Gemini as written and
is never run by the shell. On Windows, double quotes inside the query are changed to single
quotes before the call.

{pstd}
{bf:Agent actions (--yolo).} By default {cmd:gemini} runs the CLI as
{cmd:gemini --yolo -p} {it:prompt}. {cmd:--yolo} tells the CLI to approve its own tool
actions without asking, which lets it run web searches and fetch pages, but also lets it run
shell commands and write files in Stata's working folder if the model decides to. Use
{opt noyolo} to turn this off; plain questions still work, but some tools may then be
unavailable.

{pstd}
{bf:Errors.} If the CLI cannot be started or exits with a non-zero status (for example when
it is not signed in), {cmd:gemini} shows the CLI's full error output and exits with r(498).
With {opt csv} or {opt json}, a response without a {cmd:BEGIN_DATA}...{cmd:END_DATA} block
exits with r(459) and leaves the data in memory unchanged.

{pstd}
{bf:Data files.} With {opt csv} or {opt json}, {cmd:gemini} asks Gemini to wrap the table in
the markers {cmd:BEGIN_DATA} and {cmd:END_DATA}. Markdown fence lines (lines that start with
three backticks) inside the block are dropped, and a marker may share a line with data. The
block is saved as {cmd:gemini_data.csv} or {cmd:gemini_data.json} in the working folder
(replacing any file of that name) and then imported with
{cmd:import delimited ..., varnames(1) encoding("utf-8") bindquote(strict)}, so accented
text and quoted fields with line breaks are read correctly. A plain query writes no files.

{marker options}{...}
{title:Options}

{phang}
{opt csv}: Instructs Gemini to return data in CSV format, which is then automatically imported into Stata.

{phang}
{opt json}: Instructs Gemini to return data in JSON format. The JSON is converted by Stata's own Python integration (see {help python}) using only the Python standard library, so no extra packages are needed. A JSON array of objects gives one observation per object; an object of objects gives one observation per key, with the key stored in variable {cmd:key}. Nested values are stored as JSON text.

{phang}
{opt clear}: Standard Stata option to clear existing data from memory before importing new results. Without it, changed data in memory are kept and the import stops with r(4).

{phang}
{opt path(string)}: Use this if the command cannot find your {cmd:gemini} installation. Provide the full path (e.g., {cmd:/usr/local/bin/gemini} or {cmd:C:\Users\Name\AppData\Roaming\npm\gemini.cmd}).

{phang}
{opt model(string)}: Specify the model to use, for example {cmd:gemini-2.5-flash} (fast) or {cmd:gemini-2.5-pro} (complex tasks). Model names change over time; run {cmd:gemini} in a terminal to see the models your account offers.

{phang}
{opt noyolo}: Run the CLI without {cmd:--yolo}, so it does not approve its own tool actions. See {it:Agent actions} above.

{marker changes}{...}
{title:Changes}

{pstd}2.3.4 (09nov2026): the query reaches the CLI exactly as typed ({cmd:$}, {cmd:$( )} and
backticks are no longer expanded or run by the shell); {opt path()} may contain spaces; CLI
failures exit with r(498) and a csv or json response without data exits with r(459);
fenced or inline data blocks are read; imports use UTF-8 and {cmd:bindquote(strict)}; json
uses Stata's Python without pandas; plain queries no longer write files; new {opt noyolo}
option.

{pstd}2.3.3 (09nov2026): answers containing quote characters (for example {cmd:`"text"'}) no
longer stop {cmd:gemini} with r(132), and ordinary answer lines that happen to contain words
such as "at" or "message:" are no longer dropped.

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
{pstd}Ensure Stata's Python integration works ({cmd:python query}; see {help python}). If the
JSON itself is invalid, the conversion error is shown and the JSON is left in
{cmd:gemini_data.json}.{p_end}

{marker alternative}{...}
{title:Bonus: Alternative 'stata_ai' (Local LLM via Ollama)}

{pstd}
For users on macOS who require total data privacy, you can install and run a local LLM (Sandboxed) using Ollama. This allows you to generate Stata code without any data leaving your machine.
{p_end}

{pstd}
Copy and paste the following block into your Terminal. This script will install Ollama, download the Gemma 3 model, and set up a {cmd:stata_ai} alias for your terminal. Stata's {cmd:shell} does not load terminal aliases, so from Stata call Ollama directly, for example {cmd:!ollama run gemma3:12b "your query"}.
{p_end}

{pmore}
{it:# Install Ollama runner} {break}
{cmd:brew install ollama} {break}
{break}
{it:# Start Ollama in the background} {break}
{cmd:nohup ollama serve > /dev/null 2>&1 &} {break}
{break}
{it:# Pull Gemma 3 (12B) - High-accuracy for Stata} {break}
{cmd:ollama pull gemma3:12b} {break}
{break}
{it:# Create a 'stata_ai' alias for precision} {break}
{cmd:alias stata_ai='ollama run gemma3:12b "Act as an expert Stata programmer. Provide only the code, no explanation unless asked. My query: "'}
{p_end}

{phang}
{bf:Why this setup?} {p_end}
{p 8 12 2}1. {bf:Gemma 3}: Identified as a top local performer for Stata (77.8%+ accuracy). {p_end}
{p 8 12 2}2. {bf:Privacy}: The entire pipeline is local; sensitive data never leaves your computer. {p_end}


{title:Author}

{pstd}Eric A. Booth{p_end}
{pstd}eric.a.booth@gmail.com{p_end}
{pstd}Texas 2036 ({browse "https://texas2036.org/"}){p_end}
{pstd}{browse "https://github.com/ericabooth/Gemini-stata"}{p_end}
