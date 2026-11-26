#!/usr/bin/env bash
# preparar-permissoes.sh · Linux sem medo · Módulo 4
#
# O que este script faz (leia antes de rodar: regra 4!):
#   bash preparar-permissoes.sh                 cria ~/curso-linux/app-relatorios   (aulas 1 a 7)
#   bash preparar-permissoes.sh missao          cria ~/curso-linux/app-entregas     (aula 8, o chamado)
#   bash preparar-permissoes.sh conferir        confere se o chamado da aula 8 foi resolvido
#   bash preparar-permissoes.sh refazer         guarda o app-relatorios atual com outro nome e cria um novo
#   bash preparar-permissoes.sh refazer missao  o mesmo, para o app-entregas
#
# Ele só cria pastas e arquivos de texto dentro de ~/curso-linux e ajusta as
# permissões DESSES arquivos (de propósito, algumas estão erradas: é a aula).
# Não apaga nada, não instala nada e não precisa de sudo.

set -u
CURSO="$HOME/curso-linux"

if [ "$(id -u)" -eq 0 ]; then
  echo "Pare: você está como root (regra 3). Se usou sudo, rode de novo sem o sudo."
  echo "Se o seu prompt começa com root, saia com exit e entre com o seu usuário."
  exit 1
fi
mkdir -p "$CURSO"

# A opção pode vir com til (missão) ou sem (missao): as duas valem.
OPCAO="${1:-}"; SUB="${2:-}"
[ "$OPCAO" = "missão" ] && OPCAO="missao"
[ "$SUB" = "missão" ] && SUB="missao"
uso() { echo "Use: bash preparar-permissoes.sh  e uma destas opções:  missao   conferir   refazer   refazer missao"; }

# Data de ontem, às 08:00 (funciona no Linux e no Mac): assim, o ls -l mostra dia e hora, e não o ano.
ONTEM="$(date -d "1 day ago" +%Y%m%d 2>/dev/null || date -v-1d +%Y%m%d)0800"

# Cria um script de treino: só mostra mensagens e escreve em docs/.
script_treino() {
  local arq="$1" msg="$2" saida="$3"
  cat > "$arq" <<EOF
#!/usr/bin/env bash
# Script de treino do curso Linux sem medo: só escreve uma mensagem e um arquivo em docs/.
cd "\$(dirname "\$0")/.." || exit 1
echo "$msg" > "docs/$saida"
echo "$msg"
EOF
}

criar_relatorios() {
  local d="$CURSO/app-relatorios"
  mkdir -p "$d/config" "$d/scripts" "$d/docs" "$d/logs"
  printf '%s\n' "# Configuração do app-relatorios" "nome=app-relatorios" "ambiente=producao" "porta=8090" > "$d/config/app.conf"
  printf '%s\n' "# Variáveis secretas do app-relatorios (exemplo de treino: não são senhas reais)" "DB_USER=relatorios" "DB_PASSWORD=senha-de-treino-456" > "$d/.env"
  script_treino "$d/scripts/gerar-relatorio.sh" "Relatório gerado em docs/relatorio.txt (treino)." relatorio.txt
  printf '%s\n' '#!/usr/bin/env bash' 'echo "Nada para limpar (treino: este script não apaga nada)."' > "$d/scripts/limpar-temporarios.sh"
  printf '%s\n' "2026-11-13 08:00:01 INFO  app-relatorios iniciado" > "$d/logs/app-relatorios-2026-11-13.log"
  printf '%s\n' "app-relatorios: projeto de treino do curso Linux sem medo (Módulo 4)." > "$d/LEIA-ME.txt"

  # Permissões fixas (iguais no Ubuntu e no Mac). Duas estão erradas de propósito:
  chmod 755 "$d" "$d/config" "$d/scripts" "$d/docs" "$d/logs"
  chmod 644 "$d/config/app.conf" "$d/LEIA-ME.txt" "$d/logs/app-relatorios-2026-11-13.log"
  chmod 755 "$d/scripts/limpar-temporarios.sh"
  chmod 644 "$d/scripts/gerar-relatorio.sh"   # errado: falta o x para rodar
  chmod 644 "$d/.env"                         # errado: qualquer usuário pode ler o segredo
  touch -t "$ONTEM" "$d/config/app.conf" "$d/.env" "$d/LEIA-ME.txt" "$d/logs/app-relatorios-2026-11-13.log" \
    "$d/scripts/gerar-relatorio.sh" "$d/scripts/limpar-temporarios.sh"
}

criar_entregas() {
  local d="$CURSO/app-entregas"
  mkdir -p "$d/config" "$d/scripts" "$d/docs"
  printf '%s\n' "# Configuração do app-entregas" "nome=app-entregas" "ambiente=producao" "porta=8095" > "$d/config/entregas.conf"
  printf '%s\n' "# Variáveis secretas do app-entregas (exemplo de treino: não são senhas reais)" "API_TOKEN=token-de-treino-789" > "$d/.env"
  script_treino "$d/scripts/publicar.sh" "Entregas publicadas (treino)." publicado.txt
  printf '%s\n' "app-entregas: projeto de treino do curso Linux sem medo (Módulo 4)." > "$d/LEIA-ME.txt"
  chmod 755 "$d" "$d/config" "$d/scripts" "$d/docs"
  chmod 644 "$d/LEIA-ME.txt"
  chmod 644 "$d/scripts/publicar.sh"   # errado: falta o x
  chmod 666 "$d/.env"                  # errado: todo mundo lê e escreve
  chmod 777 "$d/config/entregas.conf"  # errado: todo mundo escreve
  cat > "$d/CHAMADO.txt" <<'EOF'
CHAMADO #3001 · app-entregas · prioridade normal

Oi! O app-entregas está com problemas de permissão. Pode resolver?
1. O script scripts/publicar.sh não roda. Dê ao dono a permissão de executar e rode uma vez.
2. O .env está aberto para todo mundo. Deixe que só o dono leia e escreva.
3. O config/entregas.conf está com 777. Deixe com 644.
4. Instale o programa tree (se ainda não tiver).
5. Salve a estrutura do projeto em docs/estrutura.txt usando o tree.

Quando terminar, rode estes dois comandos, um de cada vez:
  cd ~/curso-linux
  bash preparar-permissoes.sh conferir
EOF
  chmod 644 "$d/CHAMADO.txt"
}

guardar() {
  if [ -e "$CURSO/$1" ]; then
    local g; g="$1-antigo-$(date +%Y%m%d-%H%M%S)"
    mv "$CURSO/$1" "$CURSO/$g" || { echo "Não consegui guardar a pasta antiga. Não mexi em nada."; exit 1; }
    echo "A pasta antiga foi guardada como $CURSO/$g (nada foi apagado)."
  fi
}

# As 10 primeiras letras do ls -l (tipo + permissões), iguais no Ubuntu e no Mac.
perm() { ls -ld "$1" 2>/dev/null | cut -c1-10; }

case "$OPCAO" in
  "")
    if [ -e "$CURSO/app-relatorios" ]; then
      echo "A pasta $CURSO/app-relatorios já existe, então não mexi em nada."
      echo "Para começar do zero: bash preparar-permissoes.sh refazer"
      exit 1
    fi
    criar_relatorios
    echo "Pronto: o projeto está em $CURSO/app-relatorios"
    ;;
  refazer)
    if [ -n "$SUB" ] && [ "$SUB" != "missao" ]; then
      echo "Não entendi: refazer $SUB. Não mexi em nada."; uso; exit 1
    fi
    if [ "$SUB" = "missao" ]; then
      guardar app-entregas; criar_entregas
      echo "Pronto: chamado novo em $CURSO/app-entregas/CHAMADO.txt"
      exit 0
    fi
    guardar app-relatorios; criar_relatorios
    echo "Pronto: projeto novo em $CURSO/app-relatorios"
    ;;
  missao)
    if [ -e "$CURSO/app-entregas" ]; then
      echo "A pasta $CURSO/app-entregas já existe, então não mexi em nada."
      echo "Para começar o chamado do zero: bash preparar-permissoes.sh refazer missao"
      exit 1
    fi
    criar_entregas
    echo "Pronto: o chamado está em $CURSO/app-entregas/CHAMADO.txt"
    ;;
  conferir)
    d="$CURSO/app-entregas"
    if [ ! -d "$d" ]; then echo "Não achei $d. Rode antes: bash preparar-permissoes.sh missao"; exit 1; fi
    ok=0; total=0
    # item TÍTULO TESTE DICA: a dica aparece ao lado do [falta].
    item() { total=$((total + 1)); if eval "$2"; then ok=$((ok + 1)); echo "  [ok]    $1"; else echo "  [falta] $1   → $3"; fi; }
    abertos="$(find "$d" -type f -perm -0002 2>/dev/null | sed "s|^$d/||" | tr '\n' ' ')"
    doroot="$(find "$d" -user 0 2>/dev/null | sed "s|^$d/||" | tr '\n' ' ')"
    echo "Conferindo o chamado #3001:"
    item "1. publicar.sh pode ser executado pelo dono" '[ "$(perm "$d/scripts/publicar.sh" | cut -c4)" = x ]' "está $(perm "$d/scripts/publicar.sh"): falta o x do dono (u)"
    item "1. publicar.sh foi rodado (docs/publicado.txt)" '[ -f "$d/docs/publicado.txt" ]' "rode ./scripts/publicar.sh de dentro de app-entregas"
    item "2. .env só para o dono (rw-------)"          '[ "$(perm "$d/.env")" = "-rw-------" ]' "está $(perm "$d/.env"), deveria ser -rw------- (600)"
    item "3. entregas.conf com 644 (rw-r--r--)"        '[ "$(perm "$d/config/entregas.conf")" = "-rw-r--r--" ]' "está $(perm "$d/config/entregas.conf"), deveria ser -rw-r--r--"
    if command -v tree >/dev/null 2>&1 || [ "$(uname)" != "Darwin" ]; then
      item "4. tree instalado"                         'command -v tree >/dev/null 2>&1' "sudo apt update e sudo apt install tree"
    else
      echo "  [Mac]   4. tree instalado (pulado: no Mac sem Homebrew, não conta)"
    fi
    item "5. docs/estrutura.txt com a estrutura"       'grep -q "publicar.sh" "$d/docs/estrutura.txt" 2>/dev/null' "tree > docs/estrutura.txt, de dentro de app-entregas (no Mac sem tree: find . > docs/estrutura.txt)"
    item "nenhum arquivo aberto para todos, nem do root" '[ -z "$abertos" ] && [ -z "$doroot" ]' "aberto para todos: ${abertos:-nenhum} · do root: ${doroot:-nenhum} (conserte com chmod ou sudo chown)"
    echo "Resultado: $ok de $total."
    if [ "$ok" -eq "$total" ]; then
      echo "Chamado resolvido. Agora, as perguntas do Módulo 4!"
    else
      echo "Para corrigir, volte para a pasta do chamado: cd ~/curso-linux/app-entregas"
      echo "Corrija só os itens com [falta] e rode o conferir de novo."
    fi
    ;;
  *)
    echo "Opção desconhecida: $OPCAO"
    uso
    exit 1
    ;;
esac
