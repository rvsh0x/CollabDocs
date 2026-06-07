/**
 * editor-code.js — Editeur CODE avec colorisation syntaxique
 *
 * Architecture de colorisation : tokenisation en une seule passe.
 * Chaque coloriseur decoupe le texte en tokens (comment, string,
 * keyword, number, etc.) dans le bon ordre de priorite, sans jamais
 * modifier le texte source. La textarea reste intouchee.
 *
 * IDs DOM (editor-code.jsp) :
 *   #langSelector  #ceDownloadBtn  #ceExtLbl  #ceCopyBtn
 *   #ceHL  #ceGutter  #docContent  #cePos  #ceLang
 */

(function () {
    'use strict';
    
    /* ── DOM ── */
    var ta      = document.getElementById('docContent');
    var hl      = document.getElementById('ceHL');
    var gutter  = document.getElementById('ceGutter');
    var posLbl  = document.getElementById('cePos');
    var langLbl = document.getElementById('ceLang');
    var extLbl  = document.getElementById('ceExtLbl');
    var langSel = document.getElementById('langSelector');
    var dlBtn   = document.getElementById('ceDownloadBtn');
    var copyBtn = document.getElementById('ceCopyBtn');
    
    if (!ta || !hl) return;
    
    /* ══════════════════════════════════════════════════════
       TOKENISEUR GENERIQUE
       Principe : on passe une liste de regles ordonnees.
       Chaque regle { rx, cls } est testee sur le reste du texte.
       La premiere qui matche remporte le token.
       Le texte entre les tokens est echappe et emis tel quel.
       On ne modifie JAMAIS le texte source.
    ══════════════════════════════════════════════════════ */
    
    function esc(s) {
        return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    }
    
    /**
     * Tokenise `code` selon la liste de regles `rules`.
     * rules = [ { rx: RegExp (sans flag g), cls: 'cssClass' }, ... ]
     * Retourne du HTML colorie.
     * Le texte non matche est emis echape, sans modification.
     */
    function tokenize(code, rules) {
        var out   = '';
        var pos   = 0;
        var len   = code.length;
    
        while (pos < len) {
            var bestIdx   = -1;
            var bestMatch = null;
            var bestRule  = null;
    
            /* Trouver la regle qui matche le plus tot */
            for (var i = 0; i < rules.length; i++) {
                var rx = rules[i].rx;
                rx.lastIndex = pos;
                var m = rx.exec(code);
                if (m !== null && (bestIdx === -1 || m.index < bestIdx)) {
                    bestIdx   = m.index;
                    bestMatch = m;
                    bestRule  = rules[i];
                }
            }
    
            if (bestMatch === null) {
                /* Rien ne matche : emettre le reste echape */
                out += esc(code.slice(pos));
                break;
            }
    
            /* Texte avant le match : emettre echape */
            if (bestIdx > pos) {
                out += esc(code.slice(pos, bestIdx));
            }
    
            /* Le match : l'envelopper dans un span */
            var raw = bestMatch[0];
            if (bestRule.cls) {
                out += '<span class="' + bestRule.cls + '">' + esc(raw) + '</span>';
            } else {
                out += esc(raw);
            }
    
            pos = bestIdx + raw.length;
            /* Eviter boucle infinie sur match vide */
            if (raw.length === 0) pos++;
        }
    
        return out;
    }
    
    /* ══════════════════════════════════════════════════════
       REGLES PAR LANGAGE
       Ordre = priorite : la premiere regle qui matche gagne.
       Les commentaires et strings doivent etre EN PREMIER
       pour ne pas que leurs contenus soient colories.
    ══════════════════════════════════════════════════════ */
    
    /* Helper : regex avec flag g+y (sticky) pour lastIndex */
    function rx(src, fl) { return new RegExp(src, 'g' + (fl || '')); }
    
    /* ── PYTHON ── */
    var rulesPython = [
        { rx: rx('"""[\\s\\S]*?"""|\'\'\'[\\s\\S]*?\'\'\''), cls: 'cs' },  /* triple-quote */
        { rx: rx('#[^\\n]*'),                                  cls: 'cc' },  /* commentaire  */
        { rx: rx('f"(?:[^"\\\\]|\\\\.)*"|f\'(?:[^\'\\\\]|\\\\.)*\''), cls: 'cs2' }, /* f-string */
        { rx: rx('"(?:[^"\\\\]|\\\\.)*"'),                     cls: 'cs' },  /* string "     */
        { rx: rx('\'(?:[^\'\\\\]|\\\\.)*\''),                  cls: 'cs' },  /* string '     */
        { rx: rx('@[\\w.]+'),                                   cls: 'cm' },  /* decorateur   */
        { rx: rx('\\b(0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+|\\d+\\.\\d*(?:[eE][+-]?\\d+)?|\\d+)\\b'), cls: 'cn' },
        { rx: rx('\\b(True|False|None)\\b'),                    cls: 'cn' },
        { rx: rx('\\b(def|class|lambda|yield|return|if|elif|else|for|while|try|except|finally|with|import|from|as|pass|break|continue|raise|del|global|nonlocal|assert|and|or|not|in|is|async|await|match|case)\\b'), cls: 'ck' },
        { rx: rx('\\b(int|float|str|bool|list|dict|set|tuple|bytes|bytearray|type|object|None|print|len|range|enumerate|zip|map|filter|sorted|reversed|sum|min|max|abs|round|repr|input|open|super|isinstance|issubclass|hasattr|getattr|setattr|delattr|property|staticmethod|classmethod|vars|dir|id|hash|iter|next|any|all|callable|chr|ord|hex|bin|oct|format|eval|exec|compile)\\b'), cls: 'ct' },
        { rx: rx('[\\w]+(?=\\s*\\()'),                          cls: 'cf' },  /* appel        */
    ];
    
    /* ── C ── */
    var rulesC = [
        { rx: rx('\\/\\*[\\s\\S]*?\\*\\/'),                    cls: 'cc' },
        { rx: rx('\\/\\/[^\\n]*'),                             cls: 'cc' },
        { rx: rx('^[ \\t]*#[^\\n]*', 'm'),                     cls: 'cm' },  /* preprocesseur */
        { rx: rx('"(?:[^"\\\\]|\\\\.)*"'),                     cls: 'cs' },
        { rx: rx('\'(?:[^\'\\\\]|\\\\.){1,4}\''),              cls: 'cs' },
        { rx: rx('\\b(0x[0-9a-fA-F]+[uUlL]*|\\d+\\.\\d*(?:[eE][+-]?\\d+)?[fF]?|\\d+[uUlL]*)\\b'), cls: 'cn' },
        { rx: rx('\\b(auto|break|case|const|continue|default|do|else|enum|extern|for|goto|if|inline|register|restrict|return|sizeof|static|struct|switch|typedef|union|volatile|while)\\b'), cls: 'ck' },
        { rx: rx('\\b(void|char|short|int|long|float|double|signed|unsigned|bool|_Bool|size_t|ssize_t|ptrdiff_t|int8_t|int16_t|int32_t|int64_t|uint8_t|uint16_t|uint32_t|uint64_t|FILE|NULL|true|false|EOF|stdin|stdout|stderr)\\b'), cls: 'ct' },
        { rx: rx('[\\w]+(?=\\s*\\()'),                          cls: 'cf' },
    ];
    
    /* ── C++ ── */
    var rulesCpp = [
        { rx: rx('\\/\\*[\\s\\S]*?\\*\\/'),                    cls: 'cc' },
        { rx: rx('\\/\\/[^\\n]*'),                             cls: 'cc' },
        { rx: rx('^[ \\t]*#[^\\n]*', 'm'),                     cls: 'cm' },
        { rx: rx('"(?:[^"\\\\]|\\\\.)*"'),                     cls: 'cs' },
        { rx: rx('\'(?:[^\'\\\\]|\\\\.){1,4}\''),              cls: 'cs' },
        { rx: rx('\\b(0x[0-9a-fA-F]+[uUlL]*|\\d+\\.\\d*(?:[eE][+-]?\\d+)?[fFlL]?|\\d+[uUlL]*)\\b'), cls: 'cn' },
        { rx: rx('\\b(alignas|alignof|and|auto|break|case|catch|class|concept|const|consteval|constexpr|constinit|continue|co_await|co_return|co_yield|default|delete|do|else|enum|explicit|export|extern|for|friend|goto|if|inline|mutable|namespace|new|noexcept|not|operator|or|override|private|protected|public|requires|return|sizeof|static|static_assert|struct|switch|template|this|throw|try|typedef|typename|union|using|virtual|volatile|while|xor)\\b'), cls: 'ck' },
        { rx: rx('\\b(void|bool|char|char8_t|char16_t|char32_t|short|int|long|float|double|signed|unsigned|wchar_t|nullptr|true|false|size_t|string|auto|vector|map|unordered_map|set|unordered_set|pair|tuple|optional|variant|array|list|deque|unique_ptr|shared_ptr|weak_ptr|make_unique|make_shared|NULL)\\b'), cls: 'ct' },
        { rx: rx('[\\w]+(?=\\s*\\()'),                          cls: 'cf' },
    ];
    
    /* ── JAVA ── */
    var rulesJava = [
        { rx: rx('\\/\\*[\\s\\S]*?\\*\\/'),                    cls: 'cc' },
        { rx: rx('\\/\\/[^\\n]*'),                             cls: 'cc' },
        { rx: rx('"""[\\s\\S]*?"""'),                           cls: 'cs' },  /* text block */
        { rx: rx('"(?:[^"\\\\]|\\\\.)*"'),                     cls: 'cs' },
        { rx: rx('\'(?:[^\'\\\\]|\\\\.)*\''),                  cls: 'cs' },
        { rx: rx('@[\\w.]+'),                                   cls: 'cm' },
        { rx: rx('\\b(0x[0-9a-fA-F]+[lL]?|\\d+\\.\\d*(?:[eE][+-]?\\d+)?[fFdD]?|\\d+[lLfFdD]?)\\b'), cls: 'cn' },
        { rx: rx('\\b(true|false|null)\\b'),                    cls: 'cn' },
        { rx: rx('\\b(abstract|assert|break|case|catch|class|continue|default|do|else|enum|extends|final|finally|for|if|implements|import|instanceof|interface|native|new|package|permits|private|protected|public|record|return|sealed|static|super|switch|synchronized|this|throw|throws|transient|try|volatile|while|var|yield)\\b'), cls: 'ck' },
        { rx: rx('\\b(void|boolean|byte|char|short|int|long|float|double|String|Object|Number|Integer|Long|Double|Float|Boolean|Byte|Short|Character|Math|System|StringBuilder|StringBuffer|ArrayList|LinkedList|HashMap|LinkedHashMap|TreeMap|HashSet|List|Map|Set|Collection|Optional|Stream|Arrays|Collections|Exception|RuntimeException|Error)\\b'), cls: 'ct' },
        { rx: rx('\\b[A-Z][\\w]*\\b'),                          cls: 'ct' },  /* classes      */
        { rx: rx('[\\w]+(?=\\s*\\()'),                          cls: 'cf' },
    ];
    
    /* ── JAVASCRIPT ── */
    var rulesJS = [
        { rx: rx('\\/\\*[\\s\\S]*?\\*\\/'),                    cls: 'cc' },
        { rx: rx('\\/\\/[^\\n]*'),                             cls: 'cc' },
        { rx: rx('`(?:[^`\\\\]|\\\\.|\\$\\{[^}]*\\})*`'),     cls: 'cs2' }, /* template     */
        { rx: rx('"(?:[^"\\\\]|\\\\.)*"'),                     cls: 'cs' },
        { rx: rx('\'(?:[^\'\\\\]|\\\\.)*\''),                  cls: 'cs' },
        { rx: rx('\\b(0x[0-9a-fA-F]+|\\d+\\.\\d*(?:[eE][+-]?\\d+)?|\\d+n?)\\b'), cls: 'cn' },
        { rx: rx('\\b(true|false|null|undefined|NaN|Infinity|arguments)\\b'), cls: 'cn' },
        { rx: rx('\\b(break|case|catch|continue|default|delete|do|else|export|extends|finally|for|if|import|in|instanceof|new|of|return|super|switch|this|throw|try|typeof|void|while|with|yield)\\b'), cls: 'ck' },
        { rx: rx('\\b(async|await|class|const|function|let|static|var|from|as)\\b'), cls: 'ck2' },
        { rx: rx('\\b(Array|Boolean|Date|Error|Function|JSON|Map|Math|Number|Object|Promise|Reflect|RegExp|Set|String|Symbol|WeakMap|WeakSet|console|document|window|fetch|globalThis|navigator|process|self|clearInterval|clearTimeout|isFinite|isNaN|parseFloat|parseInt|setInterval|setTimeout|structuredClone)\\b'), cls: 'ct' },
        { rx: rx('[\\w$]+(?=\\s*\\()'),                         cls: 'cf' },
    ];
    
    /* ── TYPESCRIPT ── */
    var rulesTS = [
        { rx: rx('\\/\\*[\\s\\S]*?\\*\\/'),                    cls: 'cc' },
        { rx: rx('\\/\\/[^\\n]*'),                             cls: 'cc' },
        { rx: rx('`(?:[^`\\\\]|\\\\.|\\$\\{[^}]*\\})*`'),     cls: 'cs2' },
        { rx: rx('"(?:[^"\\\\]|\\\\.)*"'),                     cls: 'cs' },
        { rx: rx('\'(?:[^\'\\\\]|\\\\.)*\''),                  cls: 'cs' },
        { rx: rx('\\b(\\d+\\.\\d*(?:[eE][+-]?\\d+)?|\\d+n?)\\b'), cls: 'cn' },
        { rx: rx('\\b(true|false|null|undefined|NaN)\\b'),     cls: 'cn' },
        { rx: rx('\\b(break|case|catch|continue|default|do|else|export|extends|finally|for|if|import|in|instanceof|new|of|return|super|switch|this|throw|try|typeof|void|while|yield)\\b'), cls: 'ck' },
        { rx: rx('\\b(abstract|as|async|await|class|const|constructor|declare|enum|from|function|implements|interface|keyof|let|module|namespace|never|override|private|protected|public|readonly|static|satisfies|type|var)\\b'), cls: 'ck2' },
        { rx: rx('\\b(any|bigint|boolean|number|object|string|symbol|unknown|void|Array|Map|Promise|Record|Readonly|Required|Partial|Pick|Omit|Set|never)\\b'), cls: 'ct' },
        { rx: rx('[\\w$]+(?=\\s*\\()'),                         cls: 'cf' },
    ];
    
    /* ── GO ── */
    var rulesGo = [
        { rx: rx('\\/\\*[\\s\\S]*?\\*\\/'),                    cls: 'cc' },
        { rx: rx('\\/\\/[^\\n]*'),                             cls: 'cc' },
        { rx: rx('`[^`]*`'),                                    cls: 'cs' },  /* raw string   */
        { rx: rx('"(?:[^"\\\\]|\\\\.)*"'),                     cls: 'cs' },
        { rx: rx('\'(?:[^\'\\\\]|\\\\.)*\''),                  cls: 'cs' },
        { rx: rx('\\b(0x[0-9a-fA-F_]+|0b[01_]+|0o[0-7_]+|\\d[\\d_]*\\.?\\d*(?:[eE][+-]?\\d+)?i?)\\b'), cls: 'cn' },
        { rx: rx('\\b(true|false|nil|iota)\\b'),                cls: 'cn' },
        { rx: rx('\\b(break|case|chan|const|continue|default|defer|else|fallthrough|for|func|go|goto|if|import|interface|map|package|range|return|select|struct|switch|type|var)\\b'), cls: 'ck' },
        { rx: rx('\\b(bool|byte|complex64|complex128|error|float32|float64|int|int8|int16|int32|int64|rune|string|uint|uint8|uint16|uint32|uint64|uintptr|any|comparable|append|cap|clear|close|complex|copy|delete|imag|len|make|new|panic|print|println|real|recover)\\b'), cls: 'ct' },
        { rx: rx('[\\w]+(?=\\s*\\()'),                          cls: 'cf' },
    ];
    
    /* ── RUST ── */
    var rulesRust = [
        { rx: rx('\\/\\*[\\s\\S]*?\\*\\/'),                    cls: 'cc' },
        { rx: rx('\\/\\/[^\\n]*'),                             cls: 'cc' },
        { rx: rx('#!?\\[[\\w:(\\s,"\']*\\]'),                   cls: 'cm' },  /* attributs    */
        { rx: rx('r#?"(?:[^"\\\\]|\\\\.)*"#?'),                cls: 'cs' },  /* raw string   */
        { rx: rx('"(?:[^"\\\\]|\\\\.)*"'),                     cls: 'cs' },
        { rx: rx('\'(?:[^\'\\\\]|\\\\.)*\''),                  cls: 'cs' },
        { rx: rx('\\b(0x[0-9a-fA-F_]+|0b[01_]+|\\d[\\d_]*\\.?\\d*(?:[eE][+-]?\\d+)?(?:f32|f64|u8|u16|u32|u64|u128|usize|i8|i16|i32|i64|i128|isize)?)\\b'), cls: 'cn' },
        { rx: rx('\\b(true|false|None|Some|Ok|Err)\\b'),        cls: 'cn' },
        { rx: rx('\\b(as|async|await|break|const|continue|crate|dyn|else|enum|extern|fn|for|if|impl|in|let|loop|macro_rules|match|mod|move|mut|pub|ref|return|self|Self|static|struct|super|trait|type|union|unsafe|use|where|while|yield)\\b'), cls: 'ck' },
        { rx: rx('\\b(bool|char|f32|f64|i8|i16|i32|i64|i128|isize|str|u8|u16|u32|u64|u128|usize|String|Vec|HashMap|HashSet|BTreeMap|BTreeSet|Option|Result|Box|Rc|Arc|Cell|RefCell|Mutex|RwLock|Cow|Path|PathBuf|println|print|eprintln|eprint|panic|assert|assert_eq|assert_ne|todo|unimplemented|unreachable|dbg|format|vec)\\b'), cls: 'ct' },
        { rx: rx('[\\w]+(?=\\s*!?\\()'),                        cls: 'cf' },
    ];
    
    /* ── BASH ── */
    var rulesBash = [
        { rx: rx('#[^\\n]*'),                                   cls: 'cc' },
        { rx: rx('\\$\\([^)]+\\)'),                             cls: 'ca' },  /* subshell     */
        { rx: rx('"(?:[^"\\\\$]|\\\\.)*"'),                     cls: 'cs' },
        { rx: rx('\'(?:[^\'\\\\]|\\\\.)*\''),                   cls: 'cs' },
        { rx: rx('\\$\\{?[\\w]+\\}?'),                          cls: 'ca' },  /* variable     */
        { rx: rx('\\b(\\d+)\\b'),                               cls: 'cn' },
        { rx: rx('\\b(if|then|else|elif|fi|for|in|do|done|while|until|case|esac|function|select|return|exit|break|continue|shift|trap|readonly|declare|local|typeset|export|unset|eval|exec|source|true|false)\\b'), cls: 'ck' },
        { rx: rx('\\b(echo|printf|cd|ls|pwd|mkdir|rmdir|rm|cp|mv|touch|cat|head|tail|grep|sed|awk|cut|sort|uniq|wc|find|xargs|chmod|chown|ln|which|type|env|curl|wget|tar|ssh|scp|git|make|python|python3|java|gcc|npm|pip|node)\\b'), cls: 'ct' },
    ];
    
    /* ── HTML ── */
    var rulesHTML = [
        { rx: rx('<!--[\\s\\S]*?-->'),                          cls: 'cc' },
        { rx: rx('<!DOCTYPE[^>]*>',  'i'),                      cls: 'cm' },
        /* On tokenise tout le bloc de balise d'un coup pour eviter les conflits */
        { rx: rx('<\\/[\\w-]+>'),                                cls: 'cta'},  /* fermante     */
        { rx: rx('<[\\w-]+(?:\\s[^>]*)?>'),                      cls: null },  /* ouvrante (traitee separement) */
    ];
    
    /* HTML a besoin d'un coloriseur custom pour les attributs */
    function hlHTML(code) {
        var out = '';
        var pos = 0;
        var len = code.length;
        /* Regex pour les blocs de balises */
        var rxComment  = /<!--[\s\S]*?-->/g;
        var rxDoctype  = /<!DOCTYPE[^>]*>/gi;
        var rxClose    = /<\/[\w-]+>/g;
        var rxOpen     = /<([\w-]+)((?:\s+[\w-]+(?:=(?:"[^"]*"|'[^']*'|[^\s>]*))?)*\s*\/?>)/g;
    
        /* Fusionner toutes les regles en cherchant le plus proche */
        var allRx = [
            { r: rxComment, fn: function(m) { return '<span class="cc">' + esc(m) + '</span>'; } },
            { r: rxDoctype, fn: function(m) { return '<span class="cm">' + esc(m) + '</span>'; } },
            { r: rxClose,   fn: function(m) { return '<span class="cta">' + esc(m) + '</span>'; } },
            { r: rxOpen,    fn: function(m, tag, rest) {
                /* Coloriser le nom du tag et les attributs */
                var html = '&lt;<span class="cta">' + esc(tag) + '</span>';
                /* Attributs */
                var attrRx = /(\s+)([\w-]+)((?:=(?:"[^"]*"|'[^']*'|[^\s>]*))?)/g;
                var am;
                var restEsc = rest;
                var attrOut = '';
                var ap = 0;
                attrRx.lastIndex = 0;
                while ((am = attrRx.exec(rest)) !== null) {
                    attrOut += esc(rest.slice(ap, am.index));
                    attrOut += am[1]; /* espace */
                    attrOut += '<span class="cat">' + esc(am[2]) + '</span>'; /* nom attr */
                    if (am[3]) {
                        var val = am[3];
                        /* coloriser la valeur */
                        attrOut += '=<span class="cs">' + esc(val.slice(1)) + '</span>';
                    }
                    ap = am.index + am[0].length;
                }
                attrOut += esc(rest.slice(ap));
                html += attrOut;
                return html;
            }},
        ];
    
        while (pos < len) {
            var bestIdx  = -1;
            var bestFn   = null;
            var bestEnd  = -1;
            var bestRaw  = null;
            var bestArgs = null;
    
            for (var i = 0; i < allRx.length; i++) {
                allRx[i].r.lastIndex = pos;
                var m = allRx[i].r.exec(code);
                if (m && (bestIdx === -1 || m.index < bestIdx)) {
                    bestIdx  = m.index;
                    bestFn   = allRx[i].fn;
                    bestEnd  = m.index + m[0].length;
                    bestRaw  = m[0];
                    bestArgs = m;
                }
            }
    
            if (bestIdx === -1) {
                out += esc(code.slice(pos));
                break;
            }
            if (bestIdx > pos) out += esc(code.slice(pos, bestIdx));
            out += bestFn.apply(null, bestArgs);
            pos = bestEnd;
        }
        return out;
    }
    
    /* ── CSS ── */
    var rulesCSS = [
        { rx: rx('\\/\\*[\\s\\S]*?\\*\\/'),                    cls: 'cc' },
        { rx: rx('"(?:[^"\\\\]|\\\\.)*"|\'(?:[^\'\\\\]|\\\\.)*\''), cls: 'cs' },
        { rx: rx('url\\([^)]*\\)'),                             cls: 'cs' },
        { rx: rx('#[0-9a-fA-F]{3,8}\\b'),                       cls: 'cn' },
        { rx: rx('\\b(\\d+\\.?\\d*)(px|em|rem|vw|vh|vmin|vmax|%|pt|pc|cm|mm|in|ex|ch|fr|deg|rad|turn|s|ms|dpi|dpcm|dppx|svh|svw|dvh|dvw)\\b'), cls: 'cn' },
        { rx: rx('@[\\w-]+'),                                   cls: 'cm' },
        { rx: rx('--[\\w-]+'),                                  cls: 'ca' },
        { rx: rx('::?[\\w-]+'),                                 cls: 'ck' },
        { rx: rx('[\\w-]+(?=\\s*:(?!:))'),                      cls: 'ca' },
        { rx: rx('\\b(inherit|initial|revert|revert-layer|unset|none|auto|normal|bold|italic|solid|dashed|dotted|hidden|visible|absolute|relative|fixed|sticky|flex|grid|block|inline|transparent|currentColor)\\b'), cls: 'ct' },
    ];
    
    /* ── JSON ── */
    var rulesJSON = [
        { rx: rx('"(?:[^"\\\\]|\\\\.)*"(?=\\s*:)'),            cls: 'ca' }, /* cle          */
        { rx: rx('"(?:[^"\\\\]|\\\\.)*"'),                      cls: 'cs' }, /* valeur str   */
        { rx: rx('-?\\d+\\.?\\d*(?:[eE][+-]?\\d+)?\\b'),        cls: 'cn' },
        { rx: rx('\\b(true|false|null)\\b'),                    cls: 'ck' },
    ];
    
    /* ── XML ── */
    function hlXML(code) {
        /* Reutilise hlHTML mais sans le DOCTYPE specifique */
        return hlHTML(code);
    }
    
    /* ── PHP ── */
    var rulesPHP = [
        { rx: rx('\\/\\*[\\s\\S]*?\\*\\/'),                    cls: 'cc' },
        { rx: rx('\\/\\/[^\\n]*|#[^\\n]*'),                    cls: 'cc' },
        { rx: rx('"(?:[^"\\\\$]|\\\\.)*"'),                    cls: 'cs' },
        { rx: rx('\'(?:[^\'\\\\]|\\\\.)*\''),                  cls: 'cs' },
        { rx: rx('\\$\\{?[\\w]+\\}?'),                          cls: 'ca' },
        { rx: rx('<\\?php|<\\?=|\\?>'),                         cls: 'cm' },
        { rx: rx('\\b(0x[0-9a-fA-F]+|\\d+\\.?\\d*)\\b'),       cls: 'cn' },
        { rx: rx('\\b(true|false|null|TRUE|FALSE|NULL)\\b'),    cls: 'cn' },
        { rx: rx('\\b(abstract|and|as|break|callable|case|catch|class|clone|const|continue|declare|default|do|echo|else|elseif|enum|extends|final|finally|fn|for|foreach|function|global|if|implements|interface|match|namespace|new|or|print|private|protected|public|readonly|return|static|switch|throw|trait|try|unset|use|var|while|yield)\\b'), cls: 'ck' },
        { rx: rx('\\b(int|float|string|bool|array|object|void|mixed|never|self|parent|iterable|callable)\\b'), cls: 'ct' },
        { rx: rx('[\\w]+(?=\\s*\\()'),                          cls: 'cf' },
    ];
    
    /* ── SQL ── */
    var rulesSQL = [
        { rx: rx('--[^\\n]*'),                                  cls: 'cc' },
        { rx: rx('\\/\\*[\\s\\S]*?\\*\\/'),                    cls: 'cc' },
        { rx: rx('\'(?:[^\'\\\\]|\\\\.)*\''),                   cls: 'cs' },
        { rx: rx('\\b(\\d+\\.?\\d*(?:[eE][+-]?\\d+)?)\\b'),    cls: 'cn' },
        { rx: rx('\\b(SELECT|FROM|WHERE|JOIN|LEFT|RIGHT|INNER|OUTER|FULL|CROSS|ON|USING|AS|HAVING|LIMIT|OFFSET|UNION|ALL|DISTINCT|INSERT|INTO|VALUES|UPDATE|SET|DELETE|TRUNCATE|CREATE|TABLE|VIEW|INDEX|DROP|ALTER|ADD|COLUMN|RENAME|CONSTRAINT|CHECK|DEFAULT|NOT|NULL|AUTO_INCREMENT|SERIAL|AND|OR|IN|BETWEEN|LIKE|ILIKE|IS|CASE|WHEN|THEN|ELSE|END|WITH|RECURSIVE|BEGIN|COMMIT|ROLLBACK|TRANSACTION|PRIMARY|KEY|FOREIGN|REFERENCES|UNIQUE|GROUP|ORDER|BY|PARTITION|HAVING|EXISTS|EXCEPT|INTERSECT|RETURNING)\\b', 'i'), cls: 'ck' },
        { rx: rx('\\b(TINYINT|SMALLINT|INT|INTEGER|BIGINT|DECIMAL|NUMERIC|FLOAT|DOUBLE|REAL|BOOLEAN|BOOL|CHAR|VARCHAR|TEXT|BLOB|DATE|TIME|DATETIME|TIMESTAMP|JSON|UUID|SERIAL|BIGSERIAL|BYTEA|INTERVAL|ARRAY|BINARY|VARBINARY|MEDIUMTEXT|LONGTEXT|ENUM)\\b', 'i'), cls: 'ct' },
        { rx: rx('\\b(COUNT|SUM|AVG|MIN|MAX|COALESCE|NULLIF|NOW|CURRENT_DATE|CURRENT_TIMESTAMP|CONCAT|SUBSTRING|LENGTH|UPPER|LOWER|TRIM|REPLACE|ROUND|FLOOR|CEIL|ABS|MOD|CAST|CONVERT|ROW_NUMBER|RANK|DENSE_RANK|LAG|LEAD|FIRST_VALUE|LAST_VALUE|OVER|ARRAY_AGG|JSON_AGG|STRING_AGG|GROUP_CONCAT|IFNULL|NVL|IIF|GREATEST|LEAST)\\b', 'i'), cls: 'cf' },
    ];
    
    /* ── MARKDOWN ── */
    var rulesMD = [
        { rx: rx('```[\\s\\S]*?```'),                           cls: 'cmc' }, /* code bloc    */
        { rx: rx('`[^`\\n]+`'),                                 cls: 'cmc' }, /* code inline  */
        { rx: rx('^#{1,6}[^\\n]+', 'm'),                        cls: 'cmk' }, /* titre        */
        { rx: rx('\\*\\*[^*\\n]+\\*\\*|__[^_\\n]+__'),         cls: 'cmb' }, /* gras         */
        { rx: rx('\\*[^*\\n]+\\*|_[^_\\n]+_'),                 cls: 'cmi' }, /* italique     */
        { rx: rx('\\[[^\\]]*\\]\\([^)]*\\)'),                   cls: 'cs'  }, /* lien         */
        { rx: rx('^> ?[^\\n]+', 'm'),                           cls: 'cc'  }, /* blockquote   */
        { rx: rx('^\\s*[-*+] ', 'm'),                           cls: 'ck'  }, /* liste        */
        { rx: rx('^\\s*\\d+\\. ', 'm'),                         cls: 'ck'  }, /* liste num    */
    ];
    
    /* ── PLAINTEXT ── */
    function hlPlain(code) { return esc(code); }
    
    /* ══════════════════════════════════════════════════════
       TABLE DES LANGAGES
    ══════════════════════════════════════════════════════ */
    var LANGS = {
        plaintext:  { ext: '.txt',  label: 'Texte brut',  cmt: null, blk: null,              fn: hlPlain },
        python:     { ext: '.py',   label: 'Python',       cmt: '#',  blk: null,              rules: rulesPython },
        javascript: { ext: '.js',   label: 'JavaScript',   cmt: '//', blk: ['/* ', ' */'],    rules: rulesJS },
        typescript: { ext: '.ts',   label: 'TypeScript',   cmt: '//', blk: ['/* ', ' */'],    rules: rulesTS },
        java:       { ext: '.java', label: 'Java',         cmt: '//', blk: ['/* ', ' */'],    rules: rulesJava },
        c:          { ext: '.c',    label: 'C',            cmt: '//', blk: ['/* ', ' */'],    rules: rulesC },
        cpp:        { ext: '.cpp',  label: 'C++',          cmt: '//', blk: ['/* ', ' */'],    rules: rulesCpp },
        go:         { ext: '.go',   label: 'Go',           cmt: '//', blk: ['/* ', ' */'],    rules: rulesGo },
        rust:       { ext: '.rs',   label: 'Rust',         cmt: '//', blk: ['/* ', ' */'],    rules: rulesRust },
        bash:       { ext: '.sh',   label: 'Bash / Shell', cmt: '#',  blk: null,              rules: rulesBash },
        html:       { ext: '.html', label: 'HTML',         cmt: null, blk: ['<!-- ', ' -->'], fn: hlHTML },
        css:        { ext: '.css',  label: 'CSS',          cmt: null, blk: ['/* ', ' */'],    rules: rulesCSS },
        json:       { ext: '.json', label: 'JSON',         cmt: null, blk: null,              rules: rulesJSON },
        xml:        { ext: '.xml',  label: 'XML',          cmt: null, blk: ['<!-- ', ' -->'], fn: hlXML },
        php:        { ext: '.php',  label: 'PHP',          cmt: '//', blk: ['/* ', ' */'],    rules: rulesPHP },
        sql:        { ext: '.sql',  label: 'SQL',          cmt: '--', blk: ['/* ', ' */'],    rules: rulesSQL },
        markdown:   { ext: '.md',   label: 'Markdown',     cmt: null, blk: null,              rules: rulesMD },
    };
    
    var currentLang = 'python';
    
    /* ══════════════════════════════════════════════════════
       COLORISER
    ══════════════════════════════════════════════════════ */
    function colorize() {
        var code = ta.value;
        var info = LANGS[currentLang] || LANGS.plaintext;
        var html;
        if (info.fn) {
            html = info.fn(code);
        } else if (info.rules) {
            html = tokenize(code, info.rules);
        } else {
            html = hlPlain(code);
        }
        if (html.length === 0 || html[html.length - 1] !== '\n') html += '\n';
        hl.innerHTML = html;
        /* Gouttiere */
        var lines = code.split('\n').length;
        var g = '';
        for (var i = 1; i <= lines; i++) g += i + '\n';
        gutter.textContent = g;
    }
    
    var hlTimer = null;
    function colorizeDebounced() {
        if (ta.value.length < 10000) { colorize(); return; }
        clearTimeout(hlTimer);
        hlTimer = setTimeout(colorize, 80);
    }
    
    /* ══════════════════════════════════════════════════════
       SCROLL / POSITION
    ══════════════════════════════════════════════════════ */
    function syncScroll() {
        hl.scrollTop  = ta.scrollTop;
        hl.scrollLeft = ta.scrollLeft;
        if (gutter) gutter.style.marginTop = '-' + ta.scrollTop + 'px';
    }
    
    function updatePos() {
        if (!posLbl) return;
        var s   = ta.selectionStart || 0;
        var end = ta.selectionEnd   || 0;
        var txt = ta.value.substring(0, s);
        var ln  = txt.split('\n').length;
        var col = s - txt.lastIndexOf('\n');
        posLbl.textContent = 'Ln ' + ln + ', Col ' + col + (end > s ? '  (' + (end - s) + ' sel.)' : '');
    }
    
    /* ══════════════════════════════════════════════════════
       CHANGEMENT DE LANGAGE
    ══════════════════════════════════════════════════════ */
    function setLang(l) {
        currentLang = LANGS[l] ? l : 'plaintext';
        var info = LANGS[currentLang];
        if (langLbl) langLbl.textContent = info.label;
        /* Mettre a jour l'extension dans le bouton */
        var extEl = document.getElementById('ceExtLbl');
        if (extEl) extEl.textContent = info.ext;
        /* Synchroniser le select */
        if (langSel && langSel.value !== currentLang) langSel.value = currentLang;
        colorize();
    }
    
    if (langSel) {
        langSel.addEventListener('change', function () {
            setLang(this.value);
            notifyChange();
        });
    }
    
    /* ══════════════════════════════════════════════════════
       EVENEMENTS TEXTAREA
    ══════════════════════════════════════════════════════ */
    ta.addEventListener('input',    function () { colorizeDebounced(); updatePos(); notifyChange(); });
    ta.addEventListener('scroll',   syncScroll);
    ta.addEventListener('keyup',    updatePos);
    ta.addEventListener('click',    updatePos);
    ta.addEventListener('mouseup',  updatePos);
    
    ta.addEventListener('keydown', function (e) {
        /* Tab */
        if (e.key === 'Tab') {
            e.preventDefault();
            var s = ta.selectionStart, end = ta.selectionEnd;
            if (e.shiftKey) {
                var ls  = ta.value.lastIndexOf('\n', s - 1) + 1;
                var blk = ta.value.substring(ls, end);
                var un  = blk.replace(/^    /gm, '').replace(/^\t/gm, '');
                ta.value = ta.value.substring(0, ls) + un + ta.value.substring(end);
                ta.selectionStart = ls; ta.selectionEnd = ls + un.length;
            } else {
                ta.value = ta.value.substring(0, s) + '    ' + ta.value.substring(end);
                ta.selectionStart = ta.selectionEnd = s + 4;
            }
            colorize(); return;
        }
        /* Entree : conserver indentation */
        if (e.key === 'Enter') {
            var s2  = ta.selectionStart;
            var ls2 = ta.value.lastIndexOf('\n', s2 - 1) + 1;
            var ind = ta.value.substring(ls2, s2).match(/^(\s+)/);
            if (ind) {
                e.preventDefault();
                var ins = '\n' + ind[1];
                ta.value = ta.value.substring(0, s2) + ins + ta.value.substring(ta.selectionEnd);
                ta.selectionStart = ta.selectionEnd = s2 + ins.length;
                colorize();
            }
            return;
        }
        /* Ctrl+/ : toggle commentaire */
        if ((e.ctrlKey || e.metaKey) && e.key === '/') {
            e.preventDefault();
            toggleComment();
        }
    });
    
    function toggleComment() {
        var info = LANGS[currentLang] || {};
        var tok  = info.cmt, blk = info.blk;
        var s = ta.selectionStart, e = ta.selectionEnd, val = ta.value;
        if (tok) {
            var ls    = val.lastIndexOf('\n', s - 1) + 1;
            var le    = val.indexOf('\n', e); if (le === -1) le = val.length;
            var lines = val.substring(ls, le).split('\n');
            var allC  = lines.every(function (l) { return l.trimLeft().indexOf(tok) === 0; });
            var res   = lines.map(function (l) { return allC ? l.replace(tok, '') : tok + l; });
            ta.value  = val.substring(0, ls) + res.join('\n') + val.substring(le);
            ta.selectionStart = Math.max(ls, s + (allC ? -tok.length : tok.length));
            ta.selectionEnd   = e + (allC ? -1 : 1) * tok.length * lines.length;
        } else if (blk) {
            var sel = val.substring(s, e) || val;
            ta.value = val.substring(0, s) + blk[0] + sel + blk[1] + val.substring(e);
            ta.selectionStart = s + blk[0].length;
            ta.selectionEnd   = e + blk[0].length;
        }
        colorize();
    }
    
    /* ══════════════════════════════════════════════════════
       TELECHARGEMENT
    ══════════════════════════════════════════════════════ */
    if (dlBtn) {
        dlBtn.addEventListener('click', function () {
            var info = LANGS[currentLang] || LANGS.plaintext;
            var blob = new Blob([ta.value], { type: 'text/plain;charset=utf-8' });
            var url  = URL.createObjectURL(blob);
            var a    = document.createElement('a');
            a.href = url; a.download = 'code' + info.ext;
            document.body.appendChild(a); a.click(); document.body.removeChild(a);
            setTimeout(function () { URL.revokeObjectURL(url); }, 5000);
            dlBtn.classList.add('ce-ok');
            setTimeout(function () { dlBtn.classList.remove('ce-ok'); }, 1500);
        });
    }
    
    /* ══════════════════════════════════════════════════════
       COPIER
    ══════════════════════════════════════════════════════ */
    if (copyBtn) {
        copyBtn.addEventListener('click', function () {
            function flash() {
                var old = copyBtn.textContent;
                copyBtn.textContent = 'Copie !';
                copyBtn.classList.add('ce-ok');
                setTimeout(function () { copyBtn.textContent = old; copyBtn.classList.remove('ce-ok'); }, 1500);
            }
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(ta.value).then(flash).catch(function () {
                    ta.select(); document.execCommand('copy'); flash();
                });
            } else { ta.select(); document.execCommand('copy'); flash(); }
        });
    }
    
    /* ══════════════════════════════════════════════════════
       API PUBLIQUE — editor.js (WebSocket + sauvegarde)
       Format : { language: string, text: string }
       Le code dans `text` n'est JAMAIS modifie.
    ══════════════════════════════════════════════════════ */
    window.EDITOR_getContent = function () {
        return JSON.stringify({ language: currentLang, text: ta.value });
    };
    
    window.EDITOR_setContent = function (jsonStr) {
        if (!jsonStr) return;
        var obj;
        try { obj = JSON.parse(jsonStr); } catch (e) {
            if (ta.value !== jsonStr) ta.value = jsonStr;
            colorize(); return;
        }
        var newText = (obj && obj.text !== undefined) ? String(obj.text) : '';
        var newLang = (obj && obj.language && LANGS[obj.language]) ? obj.language : null;
        if (newText !== ta.value) {
            var sc = ta.scrollTop, pos = ta.selectionStart;
            ta.value = newText;
            ta.scrollTop = sc;
            try { ta.setSelectionRange(Math.min(pos, newText.length), Math.min(pos, newText.length)); } catch (ex) {}
        }
        if (newLang && newLang !== currentLang) setLang(newLang);
        else colorize();
    };
    
    var sendTimer = null;
    function notifyChange() {
        if (!window.EDITOR_send) return;
        clearTimeout(sendTimer);
        sendTimer = setTimeout(function () {
            window.EDITOR_send({ type: 'content_update', content: window.EDITOR_getContent() });
        }, 300);
    }
    
    /* ══════════════════════════════════════════════════════
       INIT
    ══════════════════════════════════════════════════════ */
    setLang('python');
    updatePos();
    
    }());