#!/usr/bin/env bash
# preparar-cenario.sh · Linux sem medo · Módulo 2
#
# O que este script faz (leia antes de rodar: regra 4!):
#   bash preparar-cenario.sh           cria ~/curso-linux/app-pedidos   (aulas 1 a 6)
#   bash preparar-cenario.sh missao    cria ~/curso-linux/app-estoque   (aula 7, o chamado)
#   bash preparar-cenario.sh conferir  confere se o chamado da aula 7 foi resolvido
#   bash preparar-cenario.sh refazer   guarda o app-pedidos atual com outro nome e cria um novo
#   bash preparar-cenario.sh refazer missao   o mesmo, para o app-estoque do chamado
#
# Ele só cria pastas e arquivos de texto dentro de ~/curso-linux.
# Não apaga nada, não instala nada e não precisa de sudo.
# As datas dos arquivos são ajustadas para os últimos dias (os nomes dos logs não mudam).

set -u
CURSO="$HOME/curso-linux"

if [ "$(id -u)" -eq 0 ]; then
  echo "Pare: você está como root (regra 3). Saia com exit e entre com o seu usuário."
  exit 1
fi
mkdir -p "$CURSO"

# A opção pode vir com til (missão) ou sem (missao): as duas valem.
OPCAO="${1:-}"; SUB="${2:-}"
[ "$OPCAO" = "missão" ] && OPCAO="missao"
[ "$SUB" = "missão" ] && SUB="missao"
uso() { echo "Use: bash preparar-cenario.sh [missao | conferir | refazer | refazer missao]"; }

# escreve um arquivo de log com a data do dia ($2) e algumas linhas
log() {
  local arq="$1" dia="$2" porta="$3"
  {
    echo "$dia 09:00:01 INFO  app iniciado na porta $porta"
    echo "$dia 09:15:42 INFO  pedido criado"
    echo "$dia 10:02:17 ERROR falha ao conectar no banco de dados"
    echo "$dia 10:02:20 INFO  nova tentativa de conexão: ok"
    echo "$dia 18:30:00 INFO  app encerrado"
  } > "$arq"
}

# Data de modificação de alguns dias atrás (funciona no Linux e no Mac).
# Uso: data DIAS-ATRÁS hhmm ARQUIVO. Assim, o ls -l mostra dia e hora, e não o ano.
data() {
  local dia
  dia="$(date -d "$1 days ago" +%Y%m%d 2>/dev/null || date -v-"$1"d +%Y%m%d)"
  touch -t "$dia$2" "$3"
}

criar_app() {
  local nome="$1" conf="$2" dir="$CURSO/$1"
  mkdir -p "$dir/config" "$dir/logs" "$dir/scripts" "$dir/teste-antigo"

  cat > "$dir/config/$conf" <<EOF
# Configuração do $nome
nome=$nome
ambiente=producao
porta=8080
log_dir=logs
EOF
  cp "$dir/config/$conf" "$dir/$conf.old"
  cp "$dir/config/$conf" "$dir/copia de $conf"

  cat > "$dir/.env" <<EOF
# Variáveis secretas do $nome (exemplo de treino: não são senhas reais)
DB_USER=$nome
DB_PASSWORD=senha-de-treino-123
EOF

  cat > "$dir/LEIA-ME.txt" <<EOF
$nome: projeto de treino do curso Linux sem medo.
config/   configurações
logs/     registros do sistema, um arquivo por dia
scripts/  scripts de manutenção
EOF

  cat > "$dir/scripts/iniciar.sh" <<EOF
#!/usr/bin/env bash
echo "Iniciando $nome (treino: este script não inicia nada de verdade)."
EOF

  for d in 10 11 12 13; do
    log "$dir/logs/$nome-2026-11-$d.log" "2026-11-$d" 8080
    data $((14 - d)) 1830 "$dir/logs/$nome-2026-11-$d.log"   # o do dia 13 fica com a data de ontem
  done
  log "$dir/erro-antigo.log" "2026-11-01" 8080
  log "$dir/$nome-2026-11-09.log" "2026-11-09" 8080
  : > "$dir/rascunho.txt"
  echo "teste 1" > "$dir/teste-antigo/teste1.txt"
  echo "teste 2" > "$dir/teste-antigo/teste2.txt"

  data 13 0900 "$dir/erro-antigo.log"
  data 5 1830 "$dir/$nome-2026-11-09.log"
  data 30 0800 "$dir/$conf.old"
  data 9 1400 "$dir/copia de $conf"
  data 25 0800 "$dir/teste-antigo/teste1.txt"
  data 25 0800 "$dir/teste-antigo/teste2.txt"
}

escrever_chamado() {
  cat > "$CURSO/app-estoque/CHAMADO.txt" <<'EOF'
CHAMADO #1234 · app-estoque · prioridade normal

Oi! A pasta do app-estoque está uma bagunça. Pode organizar?
1. Crie as pastas backup e arquivo dentro de app-estoque.
2. Faça um backup de config/estoque.conf em backup/estoque.conf.bak
3. Em config/estoque.conf, mude a porta de 8080 para 9090.
4. Mova o log solto app-estoque-2026-11-09.log para logs.
5. Mova estoque.conf.old e erro-antigo.log para arquivo.
6. Apague rascunho.txt, "copia de estoque.conf" e a pasta teste-antigo.

Quando terminar, rode estes dois comandos, um de cada vez:
  cd ~/curso-linux
  bash preparar-cenario.sh conferir
EOF
}

case "$OPCAO" in
  "")
    if [ -e "$CURSO/app-pedidos" ]; then
      echo "A pasta $CURSO/app-pedidos já existe, então não mexi em nada."
      echo "Para começar do zero: bash preparar-cenario.sh refazer"
      exit 1
    fi
    criar_app app-pedidos app.conf
    echo "Pronto: o projeto está em $CURSO/app-pedidos"
    ;;
  refazer)
    if [ -n "$SUB" ] && [ "$SUB" != "missao" ]; then
      echo "Não entendi: refazer $SUB. Não mexi em nada."; uso; exit 1
    fi
    if [ "$SUB" = "missao" ]; then
      if [ -e "$CURSO/app-estoque" ]; then
        guardado="app-estoque-antigo-$(date +%Y%m%d-%H%M%S)"
        mv "$CURSO/app-estoque" "$CURSO/$guardado" || { echo "Não consegui guardar a pasta antiga. Não mexi em nada."; exit 1; }
        echo "A pasta antiga foi guardada como $CURSO/$guardado (nada foi apagado)."
      fi
      criar_app app-estoque estoque.conf
      escrever_chamado
      echo "Pronto: chamado novo em $CURSO/app-estoque/CHAMADO.txt"
      exit 0
    fi
    if [ -e "$CURSO/app-pedidos" ]; then
      guardado="app-pedidos-antigo-$(date +%Y%m%d-%H%M%S)"
      mv "$CURSO/app-pedidos" "$CURSO/$guardado" || { echo "Não consegui guardar a pasta antiga. Não mexi em nada."; exit 1; }
      echo "A pasta antiga foi guardada como $CURSO/$guardado (nada foi apagado)."
    fi
    criar_app app-pedidos app.conf
    echo "Pronto: projeto novo em $CURSO/app-pedidos (como no começo da aula 1)."
    ;;
  missao)
    if [ -e "$CURSO/app-estoque" ]; then
      echo "A pasta $CURSO/app-estoque já existe, então não mexi em nada."
      echo "Para começar o chamado do zero: bash preparar-cenario.sh refazer missao"
      exit 1
    fi
    criar_app app-estoque estoque.conf
    escrever_chamado
    echo "Pronto: o chamado está em $CURSO/app-estoque/CHAMADO.txt"
    ;;
  conferir)
    d="$CURSO/app-estoque"
    if [ ! -d "$d" ]; then echo "Não achei $d. Rode antes: bash preparar-cenario.sh missao"; exit 1; fi
    ok=0; total=0
    item() { total=$((total + 1)); if eval "$2"; then ok=$((ok + 1)); echo "  [ok]    $1"; else echo "  [falta] $1"; fi; }
    echo "Conferindo o chamado #1234:"
    item "1. pastas backup e arquivo"            '[ -d "$d/backup" ] && [ -d "$d/arquivo" ]'
    item "2. backup/estoque.conf.bak com porta 8080" 'grep -q "^porta=8080" "$d/backup/estoque.conf.bak" 2>/dev/null'
    item "3. porta 9090 em config/estoque.conf"  'grep -q "^porta=9090" "$d/config/estoque.conf" 2>/dev/null'
    item "4. log solto movido para logs"         '[ -f "$d/logs/app-estoque-2026-11-09.log" ] && [ ! -e "$d/app-estoque-2026-11-09.log" ]'
    item "5. estoque.conf.old e erro-antigo.log em arquivo" '[ -f "$d/arquivo/estoque.conf.old" ] && [ -f "$d/arquivo/erro-antigo.log" ] && [ ! -e "$d/estoque.conf.old" ] && [ ! -e "$d/erro-antigo.log" ]'
    item "6. lixo apagado"                       '[ ! -e "$d/rascunho.txt" ] && [ ! -e "$d/copia de estoque.conf" ] && [ ! -e "$d/teste-antigo" ]'
    item "config, logs e .env continuam lá"     '[ -f "$d/config/estoque.conf" ] && [ -f "$d/.env" ] && [ -f "$d/logs/app-estoque-2026-11-13.log" ]'
    echo "Resultado: $ok de $total."
    if [ "$ok" -eq "$total" ]; then
      echo "Chamado resolvido. Agora, as perguntas do Módulo 2!"
    else
      echo "Corrija só os itens com [falta] e rode o conferir de novo."
      echo "Apagou algo que era para mover? Comece do zero: bash preparar-cenario.sh refazer missao"
    fi
    ;;
  *)
    echo "Opção desconhecida: $OPCAO"
    uso
    exit 1
    ;;
esac
