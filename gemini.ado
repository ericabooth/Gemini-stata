*! version 2.3.3  09nov2026
*! Eric A. Booth
*
* Changelog
*   2.3.3  09nov2026  The answer is read and printed by Mata, so lines with
*                     quotes and apostrophes (for example `"text"') no longer
*                     stop gemini with r(132). The CLI's stderr is captured
*                     separately and only stderr is noise-filtered, so answer
*                     lines such as "Note that ..." are no longer dropped. If
*                     the CLI printed no answer, its full stderr is shown.
*   2.3.2  27apr2026  Previous release.
program define gemini
    version 16.0
    syntax [anything(name=query)], [CSV JSON Clear PATH(string) MODEL(string)]

    display as text "gemini v2.3.3"
    local iswin = (c(os) == "Windows")

    if `"`query'"' == "" {
        display as error "Please provide a search query."
        exit 198
    }

    * 1. Path Setup
    local gemcmd "gemini"
    if "`path'" != "" local gemcmd "`path'"
    else {
        if !`iswin' {
            capture confirm file "/opt/homebrew/bin/gemini"
            if _rc == 0 local gemcmd "/opt/homebrew/bin/gemini"
            else {
                capture confirm file "/usr/local/bin/gemini"
                if _rc == 0 local gemcmd "/usr/local/bin/gemini"
            }
        }
    }

    * Model Setup
    local modelopt ""
    if "`model'" != "" local modelopt "-m `model'"

    * 2. Environment Setup
    local env ""
    if !`iswin' {
        local dol = char(36)
        local env `"export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:`dol'PATH; "'
    }

    * 3. Prompt Engineering
    local cleanquery : subinstr local query `"""' "'", all
    local prompt "Query: `cleanquery'. "
    if "`csv'" != "" | "`json'" != "" {
        if "`csv'" != "" {
            local prompt "`prompt' Return results as a flat CSV table only (with headers). Wrap table with markers BEGIN_DATA and END_DATA. No markdown."
        }
        else {
            local prompt "`prompt' Return results as a flat JSON array of objects only. Wrap table with markers BEGIN_DATA and END_DATA. No markdown."
        }
    }

    display as text "Consulting Gemini CLI..."
    display as text "Command: `gemcmd' `modelopt' --yolo -p..."

    * 4. Execution
    tempfile rawout rawerr
    local outfile : copy local rawout
    local errfile : copy local rawerr
    if `iswin' {
        quietly shell `gemcmd' `modelopt' --yolo -p "`prompt'" > "`outfile'" 2> "`errfile'"
    }
    else {
        ! `env' `gemcmd' `modelopt' --yolo -p "`prompt'" > "`outfile'" 2> "`errfile'"
    }

    * 5. Validation & Parsing
    capture confirm file "`outfile'"
    if _rc {
        display as error "Error: Shell failed to create output file."
        exit 601
    }

    local ext = cond("`csv'"!="", "csv", "json")
    local savedata "gemini_data.`ext'"
    
    * The answer goes through Mata so that no response text is ever placed
    * inside a Stata string or macro expansion (quotes, apostrophes and
    * backticks in answers are common in Stata coding help).
    mata: _gemini_route(st_local("outfile"), st_local("savedata"))
    capture confirm file "`errfile'"
    if !_rc {
        mata: _gemini_stderr(st_local("errfile"), `shown' == 0 & `found_any' == 0)
    }

    * 6. Memory Import
    if `found_any' {
        display as yellow _n "--- Data Processing ---"
        display as text "Data saved to: " as result `"{browse `"`c(pwd)'/`savedata'"':`savedata'}"'
        
        if "`csv'" != "" {
            local impcmd `"import delimited "`savedata'", varnames(1) `clear'"'
            display as text `"`macval(impcmd)'"'
            `impcmd'
            display as text "Data successfully imported from CSV."
        }
        else if "`json'" != "" {
            display as text "Converting JSON to memory via Python..."
            
            * Create a temporary python script to handle the conversion safely
            tempname pyscript
            file open `pyscript' using "gemini_convert.py", write replace
            file write `pyscript' "import pandas as pd; import sys" _n
            file write `pyscript' "try: df = pd.read_json('`savedata'')" _n
            file write `pyscript' "except: df = pd.read_json('`savedata'', orient='index')" _n
            file write `pyscript' "df.to_csv('gemini_temp.csv', index=False)" _n
            file close `pyscript'
            
            if `iswin' {
                quietly shell python gemini_convert.py
            }
            else {
                quietly shell /usr/bin/python3 gemini_convert.py
            }
            capture erase "gemini_convert.py"
            
            capture confirm file "gemini_temp.csv"
            if _rc == 0 {
                local impcmd `"import delimited "gemini_temp.csv", varnames(1) `clear'"'
                display as text `"`macval(impcmd)'"'
                `impcmd'
                capture erase "gemini_temp.csv"
                display as text "Data successfully imported from JSON."
            }
            else {
                display as error "JSON import failed."
                display as text "Check if the JSON in `savedata' is valid."
            }
        }
    }
    else if "`csv'`json'" != "" {
        display as error "No structured data found in the response."
        display as text "Full output from Gemini:"
        type "`outfile'"
    }
end

* Route the CLI's stdout: lines between BEGIN_DATA and END_DATA are written to
* savefn; every other non-blank line is printed as is (no SMCL, no filtering).
* Sets locals found_any (data lines written) and shown (lines printed).
mata:
void _gemini_route(string scalar infn, string scalar savefn)
{
    real scalar fin, fout, inside, found, shown
    string scalar line, t
    string matrix eof

    eof = J(0, 0, "")
    inside = 0
    found = 0
    shown = 0
    fin = _fopen(infn, "r")
    if (fin < 0) {
        errprintf("Could not open output file.\n")
        exit(601)
    }
    if (fileexists(savefn)) unlink(savefn)
    fout = _fopen(savefn, "w")
    if (fout < 0) {
        fclose(fin)
        errprintf("Could not write %s.\n", savefn)
        exit(603)
    }
    while ((line = fget(fin)) != eof) {
        line = subinstr(line, char(13), "")
        t = strtrim(line)
        if (t == "BEGIN_DATA") {
            inside = 1
            continue
        }
        if (t == "END_DATA") {
            inside = 0
            continue
        }
        if (inside) {
            fput(fout, line)
            found = 1
        }
        else if (t != "" & t != "Loaded cached credentials.") {
            display(line, 1)
            shown++
        }
    }
    fclose(fin)
    fclose(fout)
    st_local("found_any", strofreal(found))
    st_local("shown", strofreal(shown))
}

// Print the CLI's stderr. Known CLI noise (retry notices, stack frames,
// error-object fields) is dropped unless showall is nonzero, which is used
// when the CLI printed no answer at all so the user can see why.
void _gemini_stderr(string scalar fn, real scalar showall)
{
    real scalar fh, i, skip
    string scalar line, t
    string matrix eof
    string rowvector pat

    eof = J(0, 0, "")
    pat = ("Warning:*", "*color support*", "Attempt*", "Retrying*",
           "at *", "*cause:*", "*code:*", "*message:*", "*[Object]*",
           "Loaded cached credentials.*")
    fh = _fopen(fn, "r")
    if (fh < 0) return
    while ((line = fget(fh)) != eof) {
        line = subinstr(line, char(13), "")
        t = strtrim(line)
        if (t == "") continue
        skip = 0
        if (!showall) {
            for (i = 1; i <= cols(pat); i++) {
                if (strmatch(t, pat[i])) {
                    skip = 1
                    break
                }
            }
        }
        if (!skip) display(line, 1)
    }
    fclose(fh)
}
end
