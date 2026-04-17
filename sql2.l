%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sql2.tab.h"

int num_ligne = 1;
%}

SELECT      [Ss][Ee][Ll][Ee][Cc][Tt]
DISTINCT    [Dd][Ii][Ss][Tt][Ii][Nn][Cc][Tt]
ALL         [Aa][Ll][Ll]
AS          [Aa][Ss]
FROM        [Ff][Rr][Oo][Mm]
WHERE       [Ww][Hh][Ee][Rr][Ee]
GROUP       [Gg][Rr][Oo][Uu][Pp]
BY          [Bb][Yy]
HAVING      [Hh][Aa][Vv][Ii][Nn][Gg]
ORDER       [Oo][Rr][Dd][Ee][Rr]
LIMIT       [Ll][Ii][Mm][Ii][Tt]
OFFSET      [Oo][Ff][Ff][Ss][Ee][Tt]
AND         [Aa][Nn][Dd]
OR          [Oo][Rr]
NOT         [Nn][Oo][Tt]
IN          [Ii][Nn]
IS          [Ii][Ss]
LIKE        [Ll][Ii][Kk][Ee]
BETWEEN     [Bb][Ee][Tt][Ww][Ee][Ee][Nn]
ASC         [Aa][Ss][Cc]
DESC        [Dd][Ee][Ss][Cc]
NULL        [Nn][Uu][Ll][Ll]
DELETE      [Dd][Ee][Ll][Ee][Tt][Ee]
UPDATE      [Uu][Pp][Dd][Aa][Tt][Ee]
SET         [Ss][Ee][Tt]
COUNT       [Cc][Oo][Uu][Nn][Tt]
SUM         [Ss][Uu][Mm]
AVG         [Aa][Vv][Gg]
MIN         [Mm][Ii][Nn]
MAX         [Mm][Aa][Xx]
UPPER       [Uu][Pp][Pp][Ee][Rr]
LOWER       [Ll][Oo][Ww][Ee][Rr]

identifiant  [a-zA-Z][a-zA-Z0-9_]*
attr_table   {identifiant}\.{identifiant}
nombre_int   [0-9]+
nombre_reel  [0-9]+\.[0-9]+([eE][+-]?[0-9]+)?
chaine       '[^']*'
date_val     [0-9]{4}-[0-9]{2}-[0-9]{2}
booleen      [Tt][Rr][Uu][Ee]|[Ff][Aa][Ll][Ss][Ee]
commentaire  "--"[^\n]*

%%

{SELECT}    { return KEYWORD_SELECT;   }
{DISTINCT}  { return KEYWORD_DISTINCT; }
{ALL}       { return KEYWORD_ALL;      }
{AS}        { return KEYWORD_AS;       }
{FROM}      { return KEYWORD_FROM;     }
{WHERE}     { return KEYWORD_WHERE;    }
{GROUP}     { return KEYWORD_GROUP;    }
{BY}        { return KEYWORD_BY;       }
{HAVING}    { return KEYWORD_HAVING;   }
{ORDER}     { return KEYWORD_ORDER;    }
{LIMIT}     { return KEYWORD_LIMIT;    }
{OFFSET}    { return KEYWORD_OFFSET;   }
{AND}       { return KEYWORD_AND;      }
{OR}        { return KEYWORD_OR;       }
{NOT}       { return KEYWORD_NOT;      }
{IN}        { return KEYWORD_IN;       }
{IS}        { return KEYWORD_IS;       }
{LIKE}      { return KEYWORD_LIKE;     }
{BETWEEN}   { return KEYWORD_BETWEEN;  }
{ASC}       { return KEYWORD_ASC;      }
{DESC}      { return KEYWORD_DESC;     }
{NULL}      { return KEYWORD_NULL;     }
{DELETE}    { return KEYWORD_DELETE;   }
{UPDATE}    { return KEYWORD_UPDATE;   }
{SET}       { return KEYWORD_SET;      }
{COUNT}     { return FUNC_COUNT;       }
{SUM}       { return FUNC_SUM;         }
{AVG}       { return FUNC_AVG;         }
{MIN}       { return FUNC_MIN;         }
{MAX}       { return FUNC_MAX;         }
{UPPER}     { return FUNC_UPPER;       }
{LOWER}     { return FUNC_LOWER;       }

{date_val}    { return DATE;         }
{booleen}     { return BOOL;         }
{nombre_reel} { return LITERAL_REEL; }
{nombre_int}  { return NUMBER;       }
{chaine}      { return STRING;       }
{commentaire} { return COMMENT;      }

"<="  { return LTE;       }
">="  { return GTE;       }
"!="  { return NEQ;       }
"<>"  { return NEQ;       }
"="   { return EQUAL;     }
"<"   { return LT;        }
">"   { return GT;        }
"+"   { return PLUS;      }
"-"   { return MINUS;     }
"*"   { return STAR;      }
"/"   { return SLASH;     }
"%"   { return PERCENT;   }
","   { return COMMA;     }
";"   { return SEMICOLON; }
"("   { return LPAREN;    }
")"   { return RPAREN;    }

{attr_table}  {
    /* ATTR_TABLE transporte aussi la chaîne (table.colonne) */
    yylval.sval = strdup(yytext);
    return ATTR_TABLE;
}

{identifiant} {
    /* IDENTIFIER transporte le nom — indispensable pour nom_table */
    yylval.sval = strdup(yytext);
    return IDENTIFIER;
}

[ \t]+  { /* ignorer espaces et tabulations */ }
\n      { num_ligne++; }

'[^']*$  {
    fprintf(stderr, "**[ERREUR LEXICALE] ligne %d ** chaine non fermee : %s\n",
            num_ligne, yytext);
}

. {
    fprintf(stderr, "**[ERREUR LEXICALE] ligne %d ** caractere inconnu : %s\n",
            num_ligne, yytext);
}

%%

int yywrap() { return 1; }
