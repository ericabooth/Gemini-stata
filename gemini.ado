*! version 2.3.4  09nov2026
*! Eric A. Booth
*
* Changelog
*   2.3.4  09nov2026  The prompt reaches the CLI exactly as typed: on macOS
*                     and Linux it is passed in single quotes, so $5, $HOME,
*                     $( ) and backticks are no longer expanded or run by the
*                     shell. The path() executable is quoted, so paths with
*                     spaces work. A CLI that is missing or exits non-zero now
*                     stops gemini with r(498) and shows its full stderr.
*                     csv and json: markdown fence lines and BEGIN_DATA or
*                     END_DATA markers on a data line are handled; no data
*                     now gives r(459); imports use encoding("utf-8") and
*                     bindquote(strict); json is converted by Stata's own
*                     Python (standard library only, no pandas). A plain
*                     query no longer writes gemini_data.* files, and the
*                     json step no longer writes helper files to the working
*                     folder. New noyolo option.
*   2.3.3  09nov2026  The answer is read and printed by Mata, so lines with
*                     quotes and apostrophes (for example `"text"') no longer
*                     stop gemini with r(132). The CLI's stderr is captured
*                     separately and only stderr is noise-filtered, so answer
*                     lines such as "Note that ..." are no longer dropped. If
*                     the CLI printed no answer, its full stderr is shown.
*   2.3.2  27apr2026  Previous release.
program define gemini
    version 16.0
    syntax [anything(name=query)], [CSV JSON Clear PATH(string) MODEL(string) NOYOLO]

    display as text "gemini v2.3.4"
    local iswin = (c(os) == "Windows")

    mata: st_local("isempty", strofreal(strtrim(st_local("query")) == ""))
    if `isempty' {
        display as error "Please provide a search query."
        exit 198
    }
    if "`csv'" != "" & "`json'" != "" {
        display as error "options csv and json may not be combined"
        exit 198
    }

    * 1. Path Setup
    local gemcmd "gemini"
    if `"`path'"' != "" local gemcmd `"`path'"'
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
    local yolo = cond("`noyolo'" == "", "--yolo", "")
    local datamode = cond("`csv'" != "", "csv", cond("`json'" != "", "json", ""))

    * 2-3. Prompt and shell command are built in Mata, so no part of the
    * query is ever expanded by Stata or by the shell.
    tempfile rawout rawerr rawst
    local outfile : copy local rawout
    local errfile : copy local rawerr
    local stfile  : copy local rawst
    mata: _gemini_cmd(`iswin')

    display as text "Consulting Gemini CLI..."
    mata: display("Command: " + st_local("dispcmd"), 1)

    * 4. Execution
    shell `macval(shcmd)'

    * 5. Validation & Parsing
    capture confirm file "`outfile'"
    if _rc {
        display as error "Error: Shell failed to create output file."
        exit 601
    }
    mata: _gemini_status(st_local("stfile"))

    tempfile rawdata
    local datafile : copy local rawdata
    if "`datamode'" == "" local datafile ""

    * The answer goes through Mata so that no response text is ever placed
    * inside a Stata string or macro expansion (quotes, apostrophes and
    * backticks in answers are common in Stata coding help).
    mata: _gemini_route(st_local("outfile"), st_local("datafile"))
    local failed = ("`clistatus'" != "0")
    capture confirm file "`errfile'"
    if !_rc {
        mata: _gemini_stderr(st_local("errfile"), (`shown' == 0 & `found_any' == 0) | `failed')
    }
    if `failed' {
        if "`clistatus'" == "." local clistatus "unknown"
        display as error "The Gemini CLI did not run successfully (exit status `clistatus')."
        display as error "Check path() and that the CLI is installed and signed in (run gemini in a terminal)."
        exit 498
    }

    * 6. Memory Import
    if "`datamode'" == "" exit

    if !`found_any' {
        display as error "No structured data found in the response."
        display as text "Full output from Gemini:"
        type "`outfile'"
        exit 459
    }

    local savedata "gemini_data.`datamode'"
    display as yellow _n "--- Data Processing ---"
    capture copy "`datafile'" "`savedata'", replace
    if _rc {
        display as text "Note: could not write `savedata' in the working folder; importing from a temporary copy."
    }
    else {
        display as text "Data saved to: " as result `"{browse `"`c(pwd)'/`savedata'"':`savedata'}"'
    }

    if "`datamode'" == "csv" {
        local impfile : copy local datafile
    }
    else {
        display as text "Converting JSON with Stata's Python..."
        tempfile rawcsv rawpy
        local impfile : copy local rawcsv
        local pyfile "`rawpy'.py"
        mata: _gemini_pyscript(st_local("pyfile"))
        capture noisily python script "`pyfile'", args(`"`datafile'"' `"`impfile'"')
        local pyrc = _rc
        capture erase "`pyfile'"
        capture confirm file "`impfile'"
        if `pyrc' | _rc {
            display as error "JSON import failed."
            if `pyrc' {
                display as text "Stata's Python could not convert the data (see the message above, and {stata python query})."
            }
            display as text "The JSON returned by Gemini is in `savedata'."
            exit cond(`pyrc', `pyrc', 459)
        }
    }

    if "`datamode'" == "csv" {
        display as text `"import delimited "`savedata'", varnames(1) encoding("utf-8") bindquote(strict) `clear'"'
    }
    import delimited using "`impfile'", varnames(1) encoding("utf-8") bindquote(strict) `clear'
    display as text "Data successfully imported from `=upper("`datamode'")'."
end

mata:
// Single-quote a string for sh/zsh: nothing inside is expanded.
string scalar _gemini_sq(string scalar s)
{
    string scalar q
    q = char(39)
    return(q + subinstr(s, q, q + char(92) + q + q) + q)
}

// Double-quote a string for cmd.exe (double quotes inside are replaced).
string scalar _gemini_dq(string scalar s)
{
    return(char(34) + subinstr(s, char(34), char(39)) + char(34))
}

// Build the prompt and the shell command from the caller's locals and
// return them in locals shcmd (to run) and dispcmd (to show).
void _gemini_cmd(real scalar iswin)
{
    string scalar query, prompt, mode, gem, model, yolo, out, err, st
    string scalar cmd, disp, dol

    query = strtrim(st_local("query"))
    if (strlen(query) >= 2 & substr(query, 1, 1) == char(34) &
        substr(query, -1, 1) == char(34)) {
        query = substr(query, 2, strlen(query) - 2)
    }
    else if (strlen(query) >= 4 & substr(query, 1, 2) == char(96) + char(34) &
        substr(query, -2, 2) == char(34) + char(39)) {
        query = substr(query, 3, strlen(query) - 4)
    }
    prompt = "Query: " + query + ". "
    mode = st_local("datamode")
    if (mode == "csv") {
        prompt = prompt + " Return results as a flat CSV table only (with headers). " +
            "Wrap table with markers BEGIN_DATA and END_DATA, each on its own line. No markdown."
    }
    else if (mode == "json") {
        prompt = prompt + " Return results as a flat JSON array of objects only. " +
            "Wrap table with markers BEGIN_DATA and END_DATA, each on its own line. No markdown."
    }
    gem   = st_local("gemcmd")
    model = st_local("model")
    yolo  = st_local("yolo")
    out   = st_local("outfile")
    err   = st_local("errfile")
    st    = st_local("stfile")
    dol   = char(36)

    if (iswin) {
        cmd = _gemini_dq(gem)
        if (model != "") cmd = cmd + " -m " + _gemini_dq(model)
        if (yolo != "")  cmd = cmd + " " + yolo
        cmd = cmd + " -p " + _gemini_dq(prompt) +
            " > " + _gemini_dq(out) + " 2> " + _gemini_dq(err) +
            " && (echo 0)> " + _gemini_dq(st) + " || (echo 1)> " + _gemini_dq(st)
        // cmd /c strips the first and last quote of a line that starts
        // with a quote, so wrap the whole line in one more pair.
        cmd = char(34) + cmd + char(34)
    }
    else {
        cmd = "export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:" +
            dol + "PATH; " + _gemini_sq(gem)
        if (model != "") cmd = cmd + " -m " + _gemini_sq(model)
        if (yolo != "")  cmd = cmd + " " + yolo
        cmd = cmd + " -p " + _gemini_sq(prompt) +
            " > " + _gemini_sq(out) + " 2> " + _gemini_sq(err) +
            "; echo " + dol + "? > " + _gemini_sq(st)
    }
    disp = gem + (model != "" ? " -m " + model : "") + (yolo != "" ? " " + yolo : "") + " -p ..."
    st_local("shcmd", cmd)
    st_local("dispcmd", disp)
}

// Read the CLI exit status written by the shell into local clistatus
// ("." when the status file is missing or unreadable).
void _gemini_status(string scalar fn)
{
    real scalar fh, v
    string scalar line

    v = .
    if (fileexists(fn)) {
        fh = _fopen(fn, "r")
        if (fh >= 0) {
            line = fget(fh)
            fclose(fh)
            if (line != J(0, 0, "")) v = strtoreal(strtrim(line))
        }
    }
    st_local("clistatus", strofreal(v))
}

// Route the CLI's stdout. With savefn non-empty, lines between BEGIN_DATA
// and END_DATA are written to savefn (markdown fence lines are skipped, and
// a marker may share a line with data). Every other non-blank line is
// printed as is (no SMCL, no filtering). Sets locals found_any and shown.
void _gemini_route(string scalar infn, string scalar savefn)
{
    real scalar fin, fout, inside, found, shown, n
    string scalar line, t
    string matrix eof

    eof = J(0, 0, "")
    inside = 0
    found = 0
    shown = 0
    fout = -1
    fin = _fopen(infn, "r")
    if (fin < 0) {
        errprintf("Could not open output file.\n")
        exit(601)
    }
    if (savefn != "") {
        if (fileexists(savefn)) unlink(savefn)
        fout = _fopen(savefn, "w")
        if (fout < 0) {
            fclose(fin)
            errprintf("Could not write %s.\n", savefn)
            exit(603)
        }
    }
    while ((line = fget(fin)) != eof) {
        line = subinstr(line, char(13), "")
        t = strtrim(line)
        if (fout < 0) {
            if (t != "" & t != "Loaded cached credentials.") {
                display(line, 1)
                shown++
            }
            continue
        }
        if (!inside & substr(t, 1, 10) == "BEGIN_DATA") {
            inside = 1
            t = strtrim(substr(t, 11, .))
            line = t
            if (t == "") continue
        }
        if (inside) {
            n = strlen(t)
            if (n >= 8 & substr(t, -8, 8) == "END_DATA") {
                inside = 0
                t = strtrim(substr(t, 1, n - 8))
                line = t
                if (t == "") continue
            }
            if (substr(t, 1, 3) == char(96) * 3) continue
            fput(fout, line)
            found = 1
        }
        else if (t != "" & t != "Loaded cached credentials.") {
            display(line, 1)
            shown++
        }
    }
    fclose(fin)
    if (fout >= 0) fclose(fout)
    st_local("found_any", strofreal(found))
    st_local("shown", strofreal(shown))
}

// Print the CLI's stderr. Known CLI noise (retry notices, stack frames,
// error-object fields) is dropped unless showall is nonzero, which is used
// when the CLI failed or printed no answer at all so the user can see why.
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

// Write the JSON-to-CSV converter run by -python script-. It uses only the
// Python standard library. A JSON array of objects gives one row per
// object; an object of objects gives one row per key (the key is stored in
// variable key); an object of lists is read column-wise. Nested values are
// stored as JSON text.
void _gemini_pyscript(string scalar fn)
{
    real scalar fh
    string colvector L
    real scalar i

    L = ("import sys, json, csv" \
         "src, dst = sys.argv[1], sys.argv[2]" \
         "with open(src, encoding='utf-8-sig') as f:" \
         "    obj = json.load(f)" \
         "if isinstance(obj, dict):" \
         "    vals = list(obj.values())" \
         "    if vals and all(isinstance(v, dict) for v in vals):" \
         "        obj = [dict([('key', k)] + list(v.items())) for k, v in obj.items()]" \
         "    elif vals and all(isinstance(v, list) for v in vals):" \
         "        n = max(len(v) for v in vals)" \
         "        obj = [dict((k, v[i] if i < len(v) else None) for k, v in obj.items()) for i in range(n)]" \
         "    else:" \
         "        obj = [obj]" \
         "if not isinstance(obj, list):" \
         "    obj = [obj]" \
         "rows = [r if isinstance(r, dict) else {'value': r} for r in obj]" \
         "cols = []" \
         "for r in rows:" \
         "    for k in r:" \
         "        if k not in cols:" \
         "            cols.append(k)" \
         "def cell(v):" \
         "    if v is None:" \
         "        return ''" \
         "    if isinstance(v, (dict, list)):" \
         "        return json.dumps(v, ensure_ascii=False)" \
         "    return str(v)" \
         "with open(dst, 'w', encoding='utf-8', newline='') as f:" \
         "    w = csv.writer(f)" \
         "    w.writerow([str(c) for c in cols])" \
         "    for r in rows:" \
         "        w.writerow([cell(r.get(c)) for c in cols])")
    if (fileexists(fn)) unlink(fn)
    fh = fopen(fn, "w")
    for (i = 1; i <= rows(L); i++) fput(fh, L[i])
    fclose(fh)
}
end
