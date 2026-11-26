#!/usr/bin/env bash
# preparar-incidente.sh · Linux sem medo · Módulo 3
#
# O que este script faz (leia antes de rodar: regra 4!):
#   bash preparar-incidente.sh                 cria ~/curso-linux/incidente-pedidos   (aulas 1 a 6)
#   bash preparar-incidente.sh ao-vivo         por 3 minutos, escreve uma linha a cada 3 segundos
#                                              no log de hoje do incidente-pedidos   (aula 2)
#   bash preparar-incidente.sh missao          cria ~/curso-linux/incidente-estoque  (aula 7)
#   bash preparar-incidente.sh conferir        confere as respostas da missão
#   bash preparar-incidente.sh refazer         guarda o incidente-pedidos atual com outro nome e cria um novo
#   bash preparar-incidente.sh refazer missao  o mesmo, para o incidente-estoque
#
# Ele só cria pastas e arquivos de texto dentro de ~/curso-linux.
# O ao-vivo acrescenta linhas a um log de treino, e o refazer muda o nome da pasta antiga.
# Não apaga nada seu, não instala nada e não precisa de sudo.
# Aviso: quem ler até o fim vai ver as respostas da missão da aula 7 (elas estão lá para o conferir).
# Os logs são inventados, mas sempre iguais: o seu vai bater com o do vídeo.

set -u
CURSO="$HOME/curso-linux"

if [ "$(id -u)" -eq 0 ]; then
  echo "Pare: você está como root (regra 3). Saia com exit e entre com o seu usuário."
  exit 1
fi
mkdir -p "$CURSO"

# A opção pode vir com til (missão) ou sem (missao), e "ao vivo" com ou sem o traço.
OPCAO="${1:-}"; SUB="${2:-}"
[ "$OPCAO" = "missão" ] && OPCAO="missao"
[ "$SUB" = "missão" ] && SUB="missao"
[ "$OPCAO" = "aovivo" ] && OPCAO="ao-vivo"
[ "$OPCAO" = "ao" ] && [ "$SUB" = "vivo" ] && OPCAO="ao-vivo"
uso() { echo "Use: bash preparar-incidente.sh  e uma destas opções:  ao-vivo   missao   conferir   refazer   refazer missao"; }

# ---------------------------------------------------------------------------
# Daqui para baixo: como os logs são inventados. Não precisa entender agora.
# ---------------------------------------------------------------------------

# Sorteio com semente fixa: os "sorteios" saem sempre na mesma ordem.
SEED=1
sortear() { SEED=$(( (SEED * 1103515245 + 12345) % 2147483648 )); R=$(( SEED / 65536 % 100 )); }

hora() { printf -v H "%02d:%02d:%02d" $(( $1 / 3600 )) $(( $1 % 3600 / 60 )) $(( $1 % 60 )); }
seg() { echo $(( 10#${1:0:2} * 3600 + 10#${1:3:2} * 60 + 10#${1:6:2} )); }

# Uma linha "normal" (antes do problema) e uma linha "com problema" (depois).
evento_normal() {
  N=$(( N + 1 ))
  if [ "$APP" = pedidos ]; then
    if   [ $R -lt 50 ]; then L="INFO  pedido $N criado (cliente $(( 2000 + R * 7 )))"
    elif [ $R -lt 85 ]; then L="INFO  pagamento aprovado (pedido $N)"
    elif [ $R -lt 97 ]; then L="INFO  e-mail de confirmação enviado (pedido $N)"
    else                     L="WARN  servico-pagamento lento ($(( 2 + N % 5 )).$R s)"; fi   # de 2 a 6 segundos: lento, mas dentro do limite antigo
  else
    if   [ $R -lt 50 ]; then L="INFO  produto $N atualizado (quantidade $R)"
    elif [ $R -lt 85 ]; then L="INFO  consulta de estoque (produto $N)"
    elif [ $R -lt 97 ]; then L="INFO  relatório parcial gerado"
    else                     L="WARN  banco de dados lento (0.$R s)"; fi
  fi
}
evento_problema() {
  N=$(( N + 1 ))
  if [ "$APP" = pedidos ]; then
    if   [ $R -lt 35 ]; then L="INFO  pedido $N criado (cliente $(( 2000 + R * 7 )))"
    elif [ $R -lt 70 ]; then L="ERROR pagamento: tempo esgotado ao chamar servico-pagamento"
    elif [ $R -lt 78 ]; then L="INFO  pagamento aprovado (pedido $N)"
    elif [ $R -lt 86 ]; then L="ERROR e-mail: confirmação não enviada (pagamento pendente)"
    elif [ $R -lt 97 ]; then L="INFO  e-mail de confirmação enviado (pedido $N)"
    else                     L="WARN  servico-pagamento lento (2.00 s)"; fi   # o app agora desiste aos 2 segundos
  else
    if   [ $R -lt 35 ]; then L="INFO  consulta de estoque (produto $N)"
    elif [ $R -lt 72 ]; then L="ERROR banco: limite de conexões atingido"
    elif [ $R -lt 80 ]; then L="INFO  produto $N atualizado (quantidade $R)"
    elif [ $R -lt 87 ]; then L="ERROR relatório: geração cancelada (banco indisponível)"
    else                     L="WARN  banco de dados lento (3.$R s)"; fi
  fi
}

# gerar_log ARQUIVO DIA INICIO FIM [RECARGA PRIMEIRO_ERRO]
# Sem RECARGA: dia normal. Com RECARGA: o problema começa no PRIMEIRO_ERRO.
# Com RECARGA="ja": o dia inteiro já está com problema.
gerar_log() {
  local arq="$1" dia="$2" t; t=$(seg "$3"); local fim; fim=$(seg "$4")
  local recarga="${5:-}" erro1=-1 rec=-1 problema=0
  if [ "$recarga" = ja ]; then problema=1
  elif [ -n "$recarga" ]; then rec=$(seg "$recarga"); erro1=$(seg "$6"); fi
  {
    hora "$t"; echo "$dia $H INFO  $NOME iniciado"
    while :; do
      sortear; t=$(( t + 10 + R ))
      if [ $rec -ge 0 ] && [ $t -ge $rec ]; then
        hora $rec; echo "$dia $H INFO  configuração recarregada: config/$CONF"; rec=-1
      fi
      if [ $erro1 -ge 0 ] && [ $t -ge $erro1 ]; then
        hora $erro1; echo "$dia $H ${ERRO_PRINCIPAL}"; erro1=-1; problema=1; t=$(( t + 5 ))
      fi
      [ $t -ge $fim ] && break
      sortear
      if [ $problema -eq 1 ]; then evento_problema; else evento_normal; fi
      hora "$t"; echo "$dia $H $L"
    done
  } > "$arq"
}

criar_incidente() {
  local dir="$CURSO/$1"
  mkdir -p "$dir/config" "$dir/logs" "$dir/docs" "$dir/arquivo/$ARQ_MES"
  SEED=$SEMENTE; N=$PRIMEIRO_N

  gerar_log "$dir/logs/$NOME-2026-11-10.log" 2026-11-10 00:00:04 23:59:30
  gerar_log "$dir/logs/$NOME-2026-11-11.log" 2026-11-11 00:00:02 23:59:30
  gerar_log "$dir/logs/$NOME-2026-11-12.log" 2026-11-12 00:00:03 23:59:30 "$RECARGA" "$PRIMEIRO_ERRO"
  gerar_log "$dir/logs/$NOME-2026-11-13.log" 2026-11-13 00:00:01 09:30:00 ja
  touch -t 202611102359 "$dir/logs/$NOME-2026-11-10.log"
  touch -t 202611112359 "$dir/logs/$NOME-2026-11-11.log"
  touch -t 202611122359 "$dir/logs/$NOME-2026-11-12.log"
  touch -t 202611130930 "$dir/logs/$NOME-2026-11-13.log"

  printf '%s\n' "# Configuração do $NOME" "nome=$NOME" "ambiente=producao" "porta=8080" "log_dir=logs" > "$dir/config/app.conf"
  printf '%s\n' "$CONF_ATUAL" > "$dir/config/$CONF"
  printf '%s\n' "$CONF_ANTIGA" > "$dir/arquivo/$ARQ_MES/$CONF.bak"
  printf '%s\n' "# Configuração de e-mail do $NOME" "servidor=smtp.interno" "remetente=nao-responda@loja.exemplo" > "$dir/config/email.conf"
  touch -t 202611122145 "$dir/config/$CONF"
  touch -t 202610010800 "$dir/config/app.conf" "$dir/config/email.conf"
  touch -t "${ARQ_MES/-/}010800" "$dir/arquivo/$ARQ_MES/$CONF.bak"

  cat > "$dir/LEIA-ME.txt" <<EOF
$1: cópia dos arquivos do servidor do $NOME, para investigação (treino do curso Linux sem medo).
config/   configurações
logs/     registros do sistema, um arquivo por dia
arquivo/  cópias antigas
docs/     coloque aqui o seu relatório
EOF
}

# Os dois cenários: o das aulas (pedidos) e o da missão (estoque).
cenario_pedidos() {
  APP=pedidos; NOME=app-pedidos; CONF=pagamento.conf; SEMENTE=1302; PRIMEIRO_N=10000
  RECARGA=21:45:12; PRIMEIRO_ERRO=21:47:03; ARQ_MES=2026-10
  ERRO_PRINCIPAL="ERROR pagamento: tempo esgotado ao chamar servico-pagamento"
  CONF_ATUAL=$'# Configuração do serviço de pagamento\nurl=http://servico-pagamento.interno:9000\ntimeout_segundos=2\ntentativas=3'
  CONF_ANTIGA=$'# Configuração do serviço de pagamento\nurl=http://servico-pagamento.interno:9000\ntimeout_segundos=30\ntentativas=3'
}
cenario_estoque() {
  APP=estoque; NOME=app-estoque; CONF=banco.conf; SEMENTE=4207; PRIMEIRO_N=500
  RECARGA=03:10:30; PRIMEIRO_ERRO=03:12:45; ARQ_MES=2026-09
  ERRO_PRINCIPAL="ERROR banco: limite de conexões atingido"
  CONF_ATUAL=$'# Configuração do banco de dados\nhost=banco.interno\nporta=5432\nmax_conexoes=5'
  CONF_ANTIGA=$'# Configuração do banco de dados\nhost=banco.interno\nporta=5432\nmax_conexoes=50'
}

escrever_chamado_pedidos() {
  cat > "$CURSO/incidente-pedidos/CHAMADO.txt" <<'EOF'
CHAMADO #2001 · app-pedidos · prioridade alta

Clientes estão dizendo que alguns pedidos falham desde ontem à noite.
A equipe copiou os arquivos do servidor para esta pasta.
Pode investigar o que aconteceu, desde quando, e o que mudou?
EOF
}

escrever_missao() {
  local d="$CURSO/incidente-estoque"
  cat > "$d/CHAMADO.txt" <<'EOF'
CHAMADO #2002 · app-estoque · prioridade alta

O relatório de estoque não saiu hoje e a equipe recebeu reclamações.
A equipe copiou os arquivos do servidor para esta pasta.
Investigue o log do dia 12 e preencha o arquivo RESPOSTAS.txt.

Quando terminar, rode estes dois comandos, um de cada vez:
  cd ~/curso-linux
  bash preparar-incidente.sh conferir
EOF
  cat > "$d/RESPOSTAS.txt" <<'EOF'
# Chamado #2002 · escreva cada resposta depois do "=", na mesma linha, e salve.
# Todas as perguntas são sobre o log do dia 12 (logs/app-estoque-2026-11-12.log).

# 1. Hora do primeiro ERROR (formato 00:00:00)
primeiro_erro=

# 2. Quantas linhas com ERROR existem no log do dia 12?
total_erros=

# 3. Qual é o erro que mais aparece? (copie a mensagem)
erro_mais_comum=

# 4. Qual arquivo de configuração foi recarregado pouco antes do problema? (ex.: config/app.conf)
arquivo_config=

# 5. Qual era o valor que mudou, na cópia antiga dessa configuração? (só o número)
valor_antigo=

# 6. E qual é o valor atual? (só o número)
valor_atual=
EOF
}

guardar() {
  if [ -e "$CURSO/$1" ]; then
    local g; g="$1-antigo-$(date +%Y%m%d-%H%M%S)"
    mv "$CURSO/$1" "$CURSO/$g" || { echo "Não consegui guardar a pasta antiga. Não mexi em nada."; exit 1; }
    echo "A pasta antiga foi guardada como $CURSO/$g (nada foi apagado)."
  fi
}

resposta() { sed -n "s/^$1 *= *//p" "$2" | head -n 1 | tr -d '\r'; }
sem_espaco() { tr -d ' \t'; }

case "$OPCAO" in
  "")
    if [ -e "$CURSO/incidente-pedidos" ]; then
      echo "A pasta $CURSO/incidente-pedidos já existe, então não mexi em nada."
      echo "Para começar do zero: bash preparar-incidente.sh refazer"
      exit 1
    fi
    cenario_pedidos; criar_incidente incidente-pedidos; escrever_chamado_pedidos
    echo "Pronto: os arquivos do incidente estão em $CURSO/incidente-pedidos"
    ;;
  refazer)
    if [ -n "$SUB" ] && [ "$SUB" != "missao" ]; then
      echo "Não entendi: refazer $SUB. Não mexi em nada."; uso; exit 1
    fi
    if [ "$SUB" = "missao" ]; then
      guardar incidente-estoque
      cenario_estoque; criar_incidente incidente-estoque; escrever_missao
      echo "Pronto: missão nova em $CURSO/incidente-estoque"
      exit 0
    fi
    guardar incidente-pedidos
    cenario_pedidos; criar_incidente incidente-pedidos; escrever_chamado_pedidos
    echo "Pronto: incidente novo em $CURSO/incidente-pedidos"
    ;;
  ao-vivo)
    arq="$CURSO/incidente-pedidos/logs/app-pedidos-2026-11-13.log"
    if [ ! -f "$arq" ]; then echo "Não achei $arq. Rode antes: bash preparar-incidente.sh"; exit 1; fi
    # Só uma simulação por vez: o arquivo de aviso guarda o número do processo e some no fim.
    aviso="$CURSO/.ao-vivo-rodando"
    if [ -f "$aviso" ] && kill -0 "$(cat "$aviso" 2>/dev/null)" 2>/dev/null; then
      echo "A simulação já está rodando: espere ela terminar (são 3 minutos)."
      echo "Para acompanhar, dentro de incidente-pedidos: tail -f logs/app-pedidos-2026-11-13.log"
      exit 1
    fi
    APP=pedidos; NOME=app-pedidos; SEED=99; N=20000
    # Continua a partir da hora da última linha do log, para a hora nunca voltar.
    ultima=$(tail -n 1 "$arq" | cut -c12-19)
    (
      t=$(( $(seg "$ultima") + 3 )); ini=$(seg 09:30:02)
      [ "$t" -lt "$ini" ] && t=$ini
      for _ in $(seq 1 60); do
        sortear; evento_problema; hora "$t"; echo "2026-11-13 $H $L" >> "$arq"
        t=$(( t + 3 )); sleep 3
      done
      rm -f "$aviso"
    ) >/dev/null 2>&1 &
    echo $! > "$aviso"
    echo "Por 3 minutos, uma linha nova entra a cada 3 segundos em:"
    echo "  $arq"
    echo "Sem pressa. Agora, dentro da pasta incidente-pedidos, rode:"
    echo "  tail -f logs/app-pedidos-2026-11-13.log"
    ;;
  missao)
    if [ -e "$CURSO/incidente-estoque" ]; then
      echo "A pasta $CURSO/incidente-estoque já existe, então não mexi em nada."
      echo "Para começar a missão do zero: bash preparar-incidente.sh refazer missao"
      exit 1
    fi
    cenario_estoque; criar_incidente incidente-estoque; escrever_missao
    echo "Pronto: o chamado está em $CURSO/incidente-estoque/CHAMADO.txt"
    ;;
  conferir)
    d="$CURSO/incidente-estoque"; r="$d/RESPOSTAS.txt"; lg="$d/logs/app-estoque-2026-11-12.log"
    if [ ! -f "$r" ] || [ ! -f "$lg" ]; then echo "Não achei $r ou o log do dia 12. Rode antes: bash preparar-incidente.sh missao"; exit 1; fi
    cenario_estoque
    certo_total=$(grep -c ERROR "$lg")
    ok=0; total=0
    item() { total=$((total + 1)); if eval "$2"; then ok=$((ok + 1)); echo "  [ok]    $1"; else echo "  [falta] $1   → $3"; fi; }
    echo "Conferindo o chamado #2002:"
    item "1. primeiro_erro"   '[ "$(resposta primeiro_erro "$r" | sem_espaco)" = "$PRIMEIRO_ERRO" ]' "só a hora, no formato 00:00:00"
    item "2. total_erros"     '[ "$(resposta total_erros "$r" | sem_espaco)" = "$certo_total" ]' "só o número de linhas com ERROR no log do dia 12"
    item "3. erro_mais_comum" 'resposta erro_mais_comum "$r" | grep -qiE "conex|limite"' "copie a mensagem que vem depois de ERROR"
    item "4. arquivo_config"  '[ "$(resposta arquivo_config "$r" | sem_espaco | sed "s|^\./||")" = "config/$CONF" ]' "com a pasta, como em config/app.conf"
    item "5. valor_antigo"    '[ "$(resposta valor_antigo "$r" | sem_espaco | sed "s/^max_conexoes=//")" = "50" ]' "só o número, da cópia antiga (pasta arquivo)"
    item "6. valor_atual"     '[ "$(resposta valor_atual "$r" | sem_espaco | sed "s/^max_conexoes=//")" = "5" ]' "só o número, do arquivo que está em config"
    echo "Resultado: $ok de $total."
    if [ "$ok" -eq "$total" ]; then
      echo "Chamado resolvido. Agora, as perguntas do Módulo 3!"
    else
      echo "Corrija só os itens com [falta], salve o RESPOSTAS.txt e rode o conferir de novo."
    fi
    ;;
  *)
    echo "Opção desconhecida: $OPCAO"
    uso
    exit 1
    ;;
esac
