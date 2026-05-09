import re
from pathlib import Path

BASE_DIR = Path(__file__).parent
OUTPUT_FILE = BASE_DIR / "TABLE-CATALOG.md"

# Regex para pegar o cabeçalho do CREATE TABLE, incluindo o nome completo [schema].[table]
CREATE_TABLE_RE = re.compile(
    r"CREATE\s+TABLE\s+(\[[^\]]+\]\.\[[^\]]+\])\s*\(",
    re.IGNORECASE | re.MULTILINE
)

def parse_table(sql_text: str):
    """
    Localiza a primeira sentença CREATE TABLE no texto.
    Retorna (full_table_name, columns_block_text) ou (None, None) se não encontrar.
    full_table_name vem no formato [schema].[table].
    """
    m = CREATE_TABLE_RE.search(sql_text)
    if not m:
        return None, None

    full_name = m.group(1)

    # Posição logo após o '(' do CREATE TABLE (...<
    start_idx = m.end()

    # Contar parênteses para saber onde termina o bloco de definição da tabela
    open_parens = 1
    i = start_idx
    while i < len(sql_text) and open_parens > 0:
        ch = sql_text[i]
        if ch == "(":
            open_parens += 1
        elif ch == ")":
            open_parens -= 1
        i += 1

    # Bloco de colunas é tudo entre o '(' e o ')' que fecha a definição da tabela
    columns_block = sql_text[start_idx:i-1].strip()
    return full_name, columns_block

def extract_column_lines(columns_block: str):
    """
    Quebra o bloco de colunas em linhas.
    Remove linhas vazias e vírgulas finais, mas mantém todo o resto AS-IS.
    """
    lines = [line.strip() for line in columns_block.splitlines()]
    lines = [ln for ln in lines if ln]  # remove vazias

    clean_lines = []
    for ln in lines:
        # Remove vírgula terminal (mas só a vírgula final; o resto fica igual)
        clean_lines.append(ln.rstrip(","))
    return clean_lines

def split_column_name_and_def(line: str):
    """
    Identifica se a linha é uma coluna do tipo:
       [ColumnName] definição...
    Retorna (col_name, full_def) ou (None, line) se não bater com o padrão.
    """
    m = re.match(r"^\[([^\]]+)\]\s+(.*)$", line)
    if not m:
        return None, line
    col_name = m.group(1)
    col_def = m.group(2)
    return col_name, col_def

def main():
    entries = []

    # Ordena pelos nomes de arquivo (0., 1., 2., ..., 100.)
    for sql_file in sorted(BASE_DIR.glob("*.sql")):
        text = sql_file.read_text(encoding="utf-8", errors="ignore")
        table_name, columns_block = parse_table(text)
        if not table_name:
            continue

        col_lines = extract_column_lines(columns_block)
        cols = []
        for line in col_lines:
            col_name, col_def = split_column_name_and_def(line)
            if col_name is None:
                # Não parece linha de coluna (pode ser constraint de tabela etc.) -> ignora
                continue
            cols.append((col_name, col_def))

        entries.append({
            "file": sql_file.name,
            "table_name": table_name,  # ex: [dbo].[Permissions]
            "columns": cols,
        })

    md_lines = []
    md_lines.append("# Catálogo de Tabelas SQL Server (AS-IS)\n")
    md_lines.append("Diretório de origem:")
    md_lines.append("`source\\\\original\\\\sqlserver\\\\8. create-table`\n")
    md_lines.append("Cada seção abaixo corresponde a um arquivo `.sql` com uma sentença `CREATE TABLE`.\n")
    md_lines.append("As colunas são apresentadas exatamente como definidas nos scripts (AS-IS).\n")
    md_lines.append("\n---\n")

    for entry in entries:
        md_lines.append(f"{entry['table_name']}\n")
        md_lines.append(f"\nArquivo: {entry['file']}\n")
        md_lines.append("\n-----------------------------------------------------------------------------------|\n")
        md_lines.append("| Coluna | Definição completa (AS-IS) |")
        md_lines.append("\n|--------------|-------------------------------------------------------------------|")

        if not entry["columns"]:
            md_lines.append("\n| *(nenhuma coluna detectada)* |  |")
        else:
            for col_name, col_def in entry["columns"]:
                # Escapar | para não quebrar a tabela markdown
                safe_def = col_def.replace("|", "\\|")
                md_lines.append(f"\n| {col_name} | {safe_def} |")

        md_lines.append("\n-----------------------------------------------------------------------------------|\n")
        md_lines.append("\n---\n\n")

    OUTPUT_FILE.write_text("".join(md_lines), encoding="utf-8")
    print(f"Catálogo gerado em: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
	