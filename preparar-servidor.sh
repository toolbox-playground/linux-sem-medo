#!/usr/bin/env bash
# preparar-servidor.sh · Linux sem medo · Módulo 5
#
# O que este script faz (leia antes de rodar: regra 4!):
#   bash preparar-servidor.sh                 cria ~/curso-linux/servidor-loja e liga um processo de treino (aulas 1 a 7)
#   bash preparar-servidor.sh processo        liga de novo o processo de treino (ele para sozinho em 2 horas,
#                                             e também quando o computador é desligado)
#   bash preparar-servidor.sh processo missao o mesmo, para o processo do chamado da aula 8
#   bash preparar-servidor.sh log             grava de novo as mensagens de treino no log do sistema
#   bash preparar-servidor.sh missao          cria ~/curso-linux/servidor-entregas (aula 8, o chamado)
#   bash preparar-servidor.sh conferir        confere se o chamado da aula 8 foi resolvido
#   bash preparar-servidor.sh refazer         guarda o servidor-loja atual com outro nome e cria um novo
#   bash preparar-servidor.sh refazer missao  o mesmo, para o servidor-entregas
#
# Ele só cria pastas e arquivos de texto dentro de ~/curso-linux. São uns 160 MB
# agora e mais uns 125 MB no modo missao, de propósito: é a aula de disco, e
# você mesmo vai apagar os arquivos grandes. Ele também escreve algumas mensagens
# de treino no log do sistema (com o comando logger) e num arquivo (logs/sistema.log),
# e liga um script de treino que só espera, sem fazer nada, e para sozinho depois de 2 horas.
# Não apaga nada, não instala nada e não precisa de sudo.
# Para liberar o espaço no fim do módulo: apague os arquivos grandes de
# servidor-loja/backups e servidor-entregas/exportacoes, e as pastas que terminam em -antigo-DATA.

set -u
CURSO="$HOME/curso-linux"
MB=1048576

if [ "$(id -u)" -eq 0 ]; then
  echo "Pare: você está como root (regra 3). Saia com exit e entre com o seu usuário."
  exit 1
fi
mkdir -p "$CURSO"

# A opção pode vir com til (missão) ou sem (missao): as duas valem.
OPCAO="${1:-}"; SUB="${2:-}"
[ "$OPCAO" = "missão" ] && OPCAO="missao"
[ "$SUB" = "missão" ] && SUB="missao"
uso() { echo "Use: bash preparar-servidor.sh  e uma destas opções:  processo   processo missao   log   missao   conferir   refazer   refazer missao"; }

# O Ubuntu está usando o systemd? (No Mac, e em alguns WSL, não.)
tem_systemd() { [ -d /run/systemd/system ]; }
aviso_systemd() {
  if [ "$(uname)" = "Linux" ] && ! tem_systemd; then
    echo
    echo "Aviso: este Ubuntu não está usando o systemd (acontece em algumas instalações do WSL)."
    echo "As aulas 4 e 5 precisam dele. O guia de apoio da aula 4 mostra como ligar, em 3 passos."
    echo "Depois de ligar, rode:  bash preparar-servidor.sh processo  e  bash preparar-servidor.sh log"
  fi
}

# Arquivo de texto de tamanho fixo (repete a mesma linha).
encher() { yes "$2" | head -c "$3" > "$1"; }

# Script de treino que fica "travado": só espera, e para sozinho depois de 2 horas.
script_travado() {
  cat > "$1" <<'EOF'
#!/usr/bin/env bash
# Script de treino do curso Linux sem medo: fica "travado" de propósito (só espera).
# Ele não faz nada e para sozinho depois de 2 horas.
fim=$(( $(date +%s) + 7200 ))
while [ "$(date +%s)" -lt "$fim" ]; do sleep 5; done
EOF
  chmod 755 "$1"
}

# Procura só o processo de treino (bash rodando o script), não outros comandos com o mesmo nome no texto.
rodando() { pgrep -f "^(/usr/bin/|/bin/)?bash [^ ]*$1\$" >/dev/null 2>&1; }

ligar() {   # $1 = caminho do script; não liga duas vezes
  if rodando "$(basename "$1")"; then
    echo "O processo $(basename "$1") já está rodando."
  else
    nohup bash "$1" >/dev/null 2>&1 &
    echo "Processo de treino ligado: $(basename "$1")"
  fi
}

# Mensagens de treino: no log do sistema (journalctl -t NOME) e, se vier uma pasta, também em PASTA/logs/sistema.log.
# Uso: registrar NOME PASTA mensagens...   (PASTA vazia = só o log do sistema)
registrar() {
  local tag="$1" dir="$2"; shift 2
  for m in "$@"; do
    logger -t "$tag" "$m" 2>/dev/null
    [ -n "$dir" ] && echo "$(date '+%b %d %H:%M:%S') $(hostname -s 2>/dev/null || hostname) $tag: $m" >> "$dir/logs/sistema.log"
  done
}
MSG_LOJA=("INFO  backup noturno iniciado" "ERROR backup noturno falhou: pouco espaço em disco" "WARN  relatório de vendas rodando há muito tempo")
MSG_ENTREGAS=("INFO  fila de entregas iniciada" "ERROR envio de e-mail falhou: servidor smtp não responde")

# Cópias das telas das aulas 4 e 5 (para quem está no Mac, ou sem systemd, praticar a leitura).
capturas() {
  local c="$1/docs/capturas"; mkdir -p "$c"
  cat > "$c/status-rodando.txt" <<'EOF'
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: active (running) since Fri 2026-11-13 20:21:17 UTC; 21s ago
   Main PID: 438 (nginx)
     CGroup: /system.slice/nginx.service
             ├─438 "nginx: master process /usr/sbin/nginx -g daemon on; master_process on;"
             └─439 "nginx: worker process"

Nov 13 20:21:17 tbxtech systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Nov 13 20:21:17 tbxtech systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
EOF
  cat > "$c/status-parado.txt" <<'EOF'
○ nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: inactive (dead) since Fri 2026-11-13 20:23:48 UTC; 6ms ago

Nov 13 20:23:48 tbxtech systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Nov 13 20:23:48 tbxtech systemd[1]: nginx.service: Deactivated successfully.
Nov 13 20:23:48 tbxtech systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
EOF
  cat > "$c/journal-nginx.txt" <<'EOF'
Nov 13 20:21:17 tbxtech systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Nov 13 20:21:17 tbxtech systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
Nov 13 20:23:48 tbxtech systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Nov 13 20:23:48 tbxtech systemd[1]: nginx.service: Deactivated successfully.
Nov 13 20:23:48 tbxtech systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Nov 13 20:24:30 tbxtech systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Nov 13 20:24:30 tbxtech systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
Nov 13 20:25:02 tbxtech systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Nov 13 20:25:02 tbxtech systemd[1]: nginx.service: Deactivated successfully.
Nov 13 20:25:02 tbxtech systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Nov 13 20:25:02 tbxtech systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Nov 13 20:25:02 tbxtech systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
EOF
}

criar_loja() {
  local d="$CURSO/servidor-loja"
  mkdir -p "$d/config" "$d/logs" "$d/backups" "$d/uploads" "$d/scripts" "$d/docs"
  printf '%s\n' "# Configuração da loja online (treino)" "nome=loja-online" "porta=80" "backup_noturno=sim" > "$d/config/loja.conf"
  for dia in 10 11 12 13; do
    encher "$d/logs/loja-2026-11-$dia.log" "2026-11-$dia 10:00:00 INFO  pedido recebido (treino)" $((MB / 2))
  done
  encher "$d/backups/dump-2026-10-01.sql" "INSERT INTO pedidos (id, cliente, total) VALUES (1, 'cliente-de-treino', 99.90);" $((150 * MB))
  # o dump é "antigo": data de 40 dias atrás (funciona no Linux e no Mac)
  touch -t "$(date -d '40 days ago' +%Y%m%d 2>/dev/null || date -v-40d +%Y%m%d)0300" "$d/backups/dump-2026-10-01.sql"
  for n in 1 2 3; do
    encher "$d/uploads/catalogo-$n.csv" "produto-de-treino;categoria;19.90" $((2 * MB))
  done
  script_travado "$d/scripts/relatorio-lento.sh"
  cat > "$d/CHAMADO.txt" <<'EOF'
CHAMADO #4000 · servidor-loja · prioridade alta

Oi! O servidor da loja está estranho desde ontem:
- tem um relatório que começou e não termina nunca;
- o disco está enchendo e o backup noturno falhou;
- e a loja precisa de um site no ar (nginx) até o fim da semana.
Pode dar uma olhada?
EOF
  chmod 644 "$d/CHAMADO.txt"
  capturas "$d"
  registrar servidor-loja "$d" "${MSG_LOJA[@]}"
}

criar_entregas() {
  local d="$CURSO/servidor-entregas"
  mkdir -p "$d/config" "$d/exportacoes" "$d/logs" "$d/scripts" "$d/docs"
  printf '%s\n' "# Configuração do servidor de entregas (treino)" "nome=servidor-entregas" "smtp=smtp.exemplo.invalid" > "$d/config/entregas.conf"
  encher "$d/exportacoes/exportacoes-2026-09.csv" "pedido-de-treino;endereco;entregue" $((120 * MB))
  encher "$d/logs/entregas-2026-11-13.log" "2026-11-13 08:00:00 INFO  entrega registrada (treino)" $((3 * MB))
  script_travado "$d/scripts/sincronizar-fila.sh"
  cat > "$d/CHAMADO.txt" <<'EOF'
CHAMADO #4001 · servidor-entregas · prioridade alta

Oi! O servidor de entregas precisa de uma revisão geral:
1. Tem um processo (sincronizar-fila.sh) travado. Pare esse processo.
2. Descubra qual pasta do projeto mais ocupa espaço. Anote em RESPOSTAS.txt.
3. O servidor-entregas registrou um erro no log do sistema. Qual? Anote.
   (No Mac, ou sem systemd: o mesmo log está em logs/sistema.log.)
4. Confira se o nginx está no ar e se liga sozinho quando a máquina reinicia.
   Se não estiver, corrija. Anote também a porta em que ele escuta.
   (No Mac: pule este item.)
5. Crie o atalho status-site, que mostra o status do nginx, e guarde no ~/.bashrc.
   (No Mac, guarde no ~/.zshrc, e faça o atalho mostrar a cópia da tela:
    cat ~/curso-linux/servidor-loja/docs/capturas/status-rodando.txt)

Quando terminar, rode estes dois comandos, um de cada vez:
  cd ~/curso-linux
  bash preparar-servidor.sh conferir
EOF
  printf '%s\n' "# Respostas do chamado #4001. Edite com o nano: escreva depois do sinal de =, na mesma linha." \
    "# maior_pasta: só o nome da pasta · erro_no_log: copie a mensagem · porta_nginx: só o número" \
    "maior_pasta=" "erro_no_log=" "porta_nginx=" > "$d/RESPOSTAS.txt"
  chmod 644 "$d/CHAMADO.txt" "$d/RESPOSTAS.txt"
  registrar servidor-entregas "$d" "${MSG_ENTREGAS[@]}"
}

guardar() {
  if [ -e "$CURSO/$1" ]; then
    local g; g="$1-antigo-$(date +%Y%m%d-%H%M%S)"
    mv "$CURSO/$1" "$CURSO/$g" || { echo "Não consegui guardar a pasta antiga. Não mexi em nada."; exit 1; }
    echo "A pasta antiga foi guardada como $CURSO/$g (nada foi apagado)."
  fi
}

# A resposta escrita no RESPOSTAS.txt: a última linha preenchida daquele campo.
resposta() {
  grep "^$1 *=" "$CURSO/servidor-entregas/RESPOSTAS.txt" 2>/dev/null | sed "s/^$1 *= *//" | grep -v '^[[:space:]]*$' | tail -n 1
}

case "$OPCAO" in
  "")
    if [ -e "$CURSO/servidor-loja" ]; then
      echo "A pasta $CURSO/servidor-loja já existe, então não mexi em nada."
      echo "O relatório de treino parou (ele para em 2 horas, ou quando o computador desliga)?"
      echo "  Ligue de novo:  bash preparar-servidor.sh processo"
      echo "Para começar do zero (cria mais 160 MB): bash preparar-servidor.sh refazer"
      exit 1
    fi
    criar_loja
    ligar "$CURSO/servidor-loja/scripts/relatorio-lento.sh"
    echo "Pronto: o servidor de treino está em $CURSO/servidor-loja"
    aviso_systemd
    ;;
  processo)
    if [ ! -f "$CURSO/servidor-loja/scripts/relatorio-lento.sh" ]; then
      echo "Não achei o servidor-loja. Rode antes: bash preparar-servidor.sh"; exit 1
    fi
    if [ "$SUB" = "missao" ]; then
      if [ ! -f "$CURSO/servidor-entregas/scripts/sincronizar-fila.sh" ]; then
        echo "Não achei o servidor-entregas. Rode antes: bash preparar-servidor.sh missao"; exit 1
      fi
      ligar "$CURSO/servidor-entregas/scripts/sincronizar-fila.sh"
    else
      ligar "$CURSO/servidor-loja/scripts/relatorio-lento.sh"
    fi
    ;;
  log)
    if [ ! -d "$CURSO/servidor-loja" ]; then echo "Não achei o servidor-loja. Rode antes: bash preparar-servidor.sh"; exit 1; fi
    registrar servidor-loja "" "${MSG_LOJA[@]}"
    [ -d "$CURSO/servidor-entregas" ] && registrar servidor-entregas "" "${MSG_ENTREGAS[@]}"
    echo "Mensagens de treino gravadas de novo no log do sistema."
    echo "Veja com: journalctl -t servidor-loja   (se já estavam lá, agora aparecem duas vezes: tudo bem)"
    aviso_systemd
    ;;
  refazer)
    if [ -n "$SUB" ] && [ "$SUB" != "missao" ]; then
      echo "Não entendi: refazer $SUB. Não mexi em nada."; uso; exit 1
    fi
    if [ "$SUB" = "missao" ]; then
      guardar servidor-entregas; criar_entregas
      ligar "$CURSO/servidor-entregas/scripts/sincronizar-fila.sh"
      echo "Pronto: chamado novo em $CURSO/servidor-entregas/CHAMADO.txt"
      exit 0
    fi
    guardar servidor-loja; criar_loja
    ligar "$CURSO/servidor-loja/scripts/relatorio-lento.sh"
    echo "Pronto: servidor de treino novo em $CURSO/servidor-loja"
    ;;
  missao)
    if [ -e "$CURSO/servidor-entregas" ]; then
      echo "A pasta $CURSO/servidor-entregas já existe, então não mexi em nada."
      echo "O processo do chamado parou sozinho antes de você parar? Ligue de novo: bash preparar-servidor.sh processo missao"
      echo "Para começar o chamado do zero (cria mais 125 MB): bash preparar-servidor.sh refazer missao"
      exit 1
    fi
    criar_entregas
    ligar "$CURSO/servidor-entregas/scripts/sincronizar-fila.sh"
    echo "Pronto: o chamado está em $CURSO/servidor-entregas/CHAMADO.txt"
    ;;
  conferir)
    d="$CURSO/servidor-entregas"
    if [ ! -d "$d" ]; then echo "Não achei $d. Rode antes: bash preparar-servidor.sh missao"; exit 1; fi
    ok=0; total=0
    # item TÍTULO TESTE DICA: a dica aparece ao lado do [falta]. As respostas certas não aparecem aqui.
    item() { total=$((total + 1)); if eval "$2"; then ok=$((ok + 1)); echo "  [ok]    $1"; else echo "  [falta] $1   → $3"; fi; }
    pasta="$(resposta maior_pasta | tr -d ' \t' | tr 'A-Z' 'a-z' | sed 's|^\./||; s|/$||')"
    porta="$(resposta porta_nginx | sed 's/.*://' | tr -cd '0-9')"
    if [ "$(uname)" = "Darwin" ]; then rc="$HOME/.zshrc"; else rc="$HOME/.bashrc"; fi
    echo "Conferindo o chamado #4001:"
    item "1. processo sincronizar-fila.sh parado"   '! rodando sincronizar-fila.sh' "ache o PID com ps aux | grep sincronizar e pare com kill"
    item "2. maior_pasta"                           '[ "$pasta" = exportacoes ]' "só o nome da pasta que mais ocupa (du -sh * | sort -h, dentro de servidor-entregas)"
    item "3. erro_no_log"                           'resposta erro_no_log | grep -qiE "smtp|e-mail|email"' "copie a mensagem da linha com ERROR (journalctl -t servidor-entregas, ou logs/sistema.log)"
    if [ "$(uname)" = "Darwin" ]; then
      echo "  [Mac]   4. nginx no ar, ligando sozinho, e a porta (pulado: no Mac não tem systemd)"
    elif ! tem_systemd; then
      echo "  [WSL]   4. nginx no ar, ligando sozinho, e a porta (pulado: o systemd não está ligado; veja o guia da aula 4)"
    else
      item "4. nginx no ar"                         '[ "$(systemctl is-active nginx 2>/dev/null)" = active ]' "systemctl is-active nginx tem que responder active"
      item "4. nginx liga sozinho"                  '[ "$(systemctl is-enabled nginx 2>/dev/null)" = enabled ]' "systemctl is-enabled nginx tem que responder enabled"
      item "4. porta_nginx"                         '[ "$porta" = 80 ]' "só o número da porta em que o nginx escuta (ss -tln)"
    fi
    item "5. atalho status-site guardado"           'grep -qE "^alias status-site=[\"'"'"']" "$rc" 2>/dev/null' "uma linha em $rc começando com alias status-site=' (com aspas depois do =)"
    echo "Resultado: $ok de $total."
    if [ "$ok" -eq "$total" ]; then
      echo "Chamado resolvido. Agora, as perguntas do Módulo 5!"
    else
      echo "Para corrigir, volte para a pasta do chamado: cd ~/curso-linux/servidor-entregas"
      echo "Corrija só os itens com [falta] (as respostas, no nano) e rode o conferir de novo."
    fi
    ;;
  *)
    echo "Opção desconhecida: $OPCAO"
    uso
    exit 1
    ;;
esac
