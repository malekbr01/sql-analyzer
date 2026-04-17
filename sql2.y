%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int num_ligne;
void yyerror(const char *s);


int nb_select = 0, nb_update = 0, nb_delete = 0;
int nb_where  = 0, nb_join   = 0;


char *tables[] = {"employes", "departements"};
int   nb_tables = 2;

int table_existe(const char *t) {
    for (int i = 0; i < nb_tables; i++)
        if (strcmp(tables[i], t) == 0) return 1;
    return 0;
}

void erreur_semantique(const char *msg) {
    fprintf(stderr, "[ERREUR SEMANTIQUE] ligne %d : %s\n", num_ligne, msg);
}
void separateur() {
    printf("\n----------------------------------------\n");
}
%}
%define parse.error verbose
%union {
    char *sval;
}

%token KEYWORD_SELECT KEYWORD_DISTINCT KEYWORD_ALL KEYWORD_AS
%token KEYWORD_FROM KEYWORD_WHERE KEYWORD_GROUP KEYWORD_BY
%token KEYWORD_HAVING KEYWORD_ORDER KEYWORD_LIMIT KEYWORD_OFFSET
%token KEYWORD_AND KEYWORD_OR KEYWORD_NOT KEYWORD_IN KEYWORD_IS
%token KEYWORD_LIKE KEYWORD_BETWEEN KEYWORD_ASC KEYWORD_DESC
%token KEYWORD_NULL KEYWORD_DELETE KEYWORD_UPDATE KEYWORD_SET
%token FUNC_COUNT FUNC_SUM FUNC_AVG FUNC_MIN FUNC_MAX
%token FUNC_UPPER FUNC_LOWER
%token <sval> IDENTIFIER ATTR_TABLE
%token NUMBER LITERAL_REEL STRING DATE BOOL
%token STAR PERCENT SLASH
%token COMMA SEMICOLON LPAREN RPAREN
%token EQUAL LT GT LTE GTE NEQ
%token PLUS MINUS
%token COMMENT

/* ── nom_table renvoie la chaîne du nom ── */
%type <sval> nom_table

%right KEYWORD_NOT
%left  KEYWORD_OR
%left  KEYWORD_AND
%nonassoc EQUAL LT GT LTE GTE NEQ
%nonassoc KEYWORD_LIKE KEYWORD_IN KEYWORD_BETWEEN KEYWORD_IS

%%

programme
    : instruction_list
    ;

instruction_list
    : instruction
    | instruction_list instruction
    ;

instruction
    : requete_select SEMICOLON {
        printf("\n[OK] SELECT valide — ligne %d\n", num_ligne);
      separateur();
	}
    | requete_update SEMICOLON {
        printf("\n[OK] UPDATE valide — ligne %d\n", num_ligne);
      }
    | requete_delete SEMICOLON {
        printf("\n[OK] DELETE valide — ligne %d\n", num_ligne);
	separateur();
      }
    | COMMENT { }
    | error SEMICOLON {
        printf("\n[ERREUR SYNTAXIQUE] Instruction invalide ligne %d\n", num_ligne);
        yyerrok;
	separateur();
      }
    ;

requete_select
    : KEYWORD_SELECT quantificateur liste_select
      KEYWORD_FROM liste_tables
      clause_where
      clause_group
      clause_having
      clause_order
      clause_limit
      { nb_select++; }
    ;

quantificateur
    :    
    | KEYWORD_DISTINCT
    | KEYWORD_ALL
    ;

liste_select
    : STAR
    | liste_expressions_alias
    ;

liste_expressions_alias
    : expression_alias
    | liste_expressions_alias COMMA expression_alias
    ;

expression_alias
    : expression
    | expression KEYWORD_AS IDENTIFIER
    | expression IDENTIFIER
    ;

requete_update
    : KEYWORD_UPDATE nom_table opt_alias
      KEYWORD_SET liste_affectations
      clause_where
      clause_order
      clause_limit
      { nb_update++; }
    ;

opt_alias
    :    
    | IDENTIFIER
    | KEYWORD_AS IDENTIFIER
    ;

liste_affectations
    : affectation
    | liste_affectations COMMA affectation
    ;

affectation
    : nom_colonne EQUAL expression
    | nom_colonne EQUAL KEYWORD_NULL
    ;

requete_delete
    : KEYWORD_DELETE KEYWORD_FROM nom_table opt_alias
      clause_where
      clause_order
      clause_limit
      { nb_delete++; }
    ;


liste_tables
    : table_alias
    | liste_tables COMMA table_alias
    ;

table_alias
    : nom_table {
        if (!table_existe($1)) {
            char msg[256];
            snprintf(msg, sizeof(msg), "table '%s' n'existe pas dans la base", $1);
            erreur_semantique(msg);
        }
        free($1);
      }
    | nom_table KEYWORD_AS IDENTIFIER {
        if (!table_existe($1)) {
            char msg[256];
            snprintf(msg, sizeof(msg), "table '%s' n'existe pas dans la base", $1);
            erreur_semantique(msg);
        }
        free($1); free($3);
      }
    | nom_table IDENTIFIER {
        if (!table_existe($1)) {
            char msg[256];
            snprintf(msg, sizeof(msg), "table '%s' n'existe pas dans la base", $1);
            erreur_semantique(msg);
        }
        free($1); free($2);
      }
    ;


nom_table
    : IDENTIFIER  { $$ = $1; }
    ;

nom_colonne
    : IDENTIFIER  { free($1); }
    | ATTR_TABLE  { free($1); }
    ;

liste_colonnes
    : nom_colonne
    | liste_colonnes COMMA nom_colonne
    ;

clause_where
    :    
    | KEYWORD_WHERE condition
      { nb_where++; }
    ;

clause_group
    :    
    | KEYWORD_GROUP KEYWORD_BY liste_colonnes
    ;

clause_having
    :    
    | KEYWORD_HAVING condition
    ;

clause_order
    :    
    | KEYWORD_ORDER KEYWORD_BY liste_order_items
    ;

liste_order_items
    : order_item
    | liste_order_items COMMA order_item
    ;

order_item
    : expression
    | expression KEYWORD_ASC
    | expression KEYWORD_DESC
    ;

clause_limit
    :    
    | KEYWORD_LIMIT NUMBER
    | KEYWORD_LIMIT NUMBER KEYWORD_OFFSET NUMBER
    ;

expression
    : valeur
    | nom_colonne
    | fonction_agregat
    | fonction_scalaire
    | expression STAR     expression
    | expression SLASH    expression
    | expression PERCENT  expression
    | expression PLUS     expression
    | expression MINUS    expression
    | LPAREN expression RPAREN
    ;

condition
    : predicat
    | condition KEYWORD_AND condition
    | condition KEYWORD_OR  condition
    | KEYWORD_NOT condition
    | LPAREN condition RPAREN
    ;

predicat
    : expression EQUAL   expression
    | expression LT      expression
    | expression GT      expression
    | expression LTE     expression
    | expression GTE     expression
    | expression NEQ     expression
    | expression KEYWORD_LIKE    STRING
    | expression KEYWORD_BETWEEN expression KEYWORD_AND expression
    | expression KEYWORD_IN LPAREN liste_valeurs RPAREN
    | expression KEYWORD_IS KEYWORD_NULL
    | expression KEYWORD_IS KEYWORD_NOT KEYWORD_NULL
    ;

fonction_agregat
    : FUNC_COUNT LPAREN STAR RPAREN
    | FUNC_COUNT LPAREN expression RPAREN
    | FUNC_SUM   LPAREN expression RPAREN
    | FUNC_AVG   LPAREN expression RPAREN
    | FUNC_MIN   LPAREN expression RPAREN
    | FUNC_MAX   LPAREN expression RPAREN
    ;

fonction_scalaire
    : FUNC_UPPER LPAREN expression RPAREN
    | FUNC_LOWER LPAREN expression RPAREN
    ;

liste_valeurs
    : valeur
    | liste_valeurs COMMA valeur
    ;

valeur
    : NUMBER
    | LITERAL_REEL
    | STRING
    | DATE
    | BOOL
    | KEYWORD_NULL
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "\n[ERREUR SYNTAXIQUE] ligne %d : %s\n", num_ligne, s);
}

int main(int argc, char *argv[]) {
    ++argv; --argc;
    if (argc > 0) {
        extern FILE *yyin;
        yyin = fopen(argv[0], "r");
        if (!yyin) {
            fprintf(stderr, "Erreur: impossible d'ouvrir %s\n", argv[0]);
            return 1;
        }
    }
    printf("=== Analyse Des Requetes SQL ===\n\n");
    yyparse();
    printf("\n=== Rapport semantique ===\n");
    printf("  SELECT : %d\n", nb_select);
    printf("  UPDATE : %d\n", nb_update);
    printf("  DELETE : %d\n", nb_delete);
    printf("  Requetes avec WHERE : %d\n", nb_where);
    printf("\n=== Analyse terminee ===\n");
    return 0;
}
