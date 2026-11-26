#!/usr/bin/env bash
# preparar-entrega.sh · Linux sem medo · Módulo 6
#
# O que este script faz (leia antes de rodar: regra 4!):
#   bash preparar-entrega.sh                 cria ~/curso-linux/site-loja (aulas 1 a 5)
#   bash preparar-entrega.sh missao          cria ~/curso-linux/site-entregas e um backup antigo (aula 6, o chamado final)
#   bash preparar-entrega.sh conferir        confere se o chamado da aula 6 foi resolvido
#   bash preparar-entrega.sh refazer         guarda o site-loja atual com outro nome e cria um novo
#   bash preparar-entrega.sh refazer missao  o mesmo, para o chamado final: guarda também a pasta de teste,
#                                            a pasta entrega e os backups do site-entregas, e começa do zero
#
# Ele só cria pastas e arquivos de treino dentro de ~/curso-linux (uns 55 MB no
# total: a pasta cache é grande de propósito, para você aprender a deixar de fora
# do backup). Não apaga nada seu (no modo missao, ele remove só um arquivo de treino
# que ele mesmo acabou de criar: é o arquivo "apagado sem querer" do chamado),
# não instala nada e não precisa de sudo.
# Apagou a pasta site-loja sem querer? Rode o script de novo, sem opção: ele recria.
# No fim do curso, se quiser liberar o espaço, a aula 6 mostra o que pode apagar.

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
uso() { echo "Use: bash preparar-entrega.sh  e uma destas opções:  missao   conferir   refazer   refazer missao"; }
AGORA="$(date +%Y%m%d-%H%M%S)"
# Se já existe algo guardado neste mesmo segundo, espera um pouco para o nome não repetir.
while ls -d "$CURSO"/*-guardada-"$AGORA" "$CURSO/backups/guardados-$AGORA" >/dev/null 2>&1; do sleep 1; AGORA="$(date +%Y%m%d-%H%M%S)"; done

# Arquivo de texto de tamanho fixo (repete a mesma linha).
encher() { yes "$2" | head -c "$3" > "$1"; }
# Arquivo de treino que quase não diminui ao compactar (como imagens de verdade).
miniaturas() { head -c "$2" /dev/urandom | base64 > "$1"; }

pagina() {   # $1 = arquivo, $2 = título
  cat > "$1" <<EOF
<!DOCTYPE html>
<html>
<head><title>$2</title></head>
<body>
<h1>$2</h1>
<p>Página de treino do curso Linux sem medo.</p>
</body>
</html>
EOF
}

criar_loja() {
  local d="$CURSO/site-loja"
  mkdir -p "$d/config" "$d/paginas" "$d/docs" "$d/cache" "$d/logs"
  printf 'nome=site-loja\nporta=80\nambiente=treino\n' > "$d/config/loja.conf"
  printf 'pagina_inicial=index.html\nitens_por_pagina=20\n' > "$d/config/vitrine.conf"
  pagina "$d/paginas/index.html" "Loja de treino"
  pagina "$d/paginas/produtos.html" "Produtos"
  pagina "$d/paginas/contato.html" "Contato"
  printf 'Notas do site-loja\n- A pasta cache guarda miniaturas das fotos. O site recria tudo sozinho.\n- Manutenção marcada para sábado.\n' > "$d/docs/notas.txt"
  encher "$d/logs/acesso.log" '2026-11-12 10:15:02 GET /produtos.html 200' $((1 * MB))
  for n in 1 2 3; do miniaturas "$d/cache/miniaturas-$n.bin" $((7 * MB)); done
  cat > "$d/CHAMADO.txt" <<'EOF'
CHAMADO #5000 · site-loja · manutenção de sábado

Oi! No sábado a gente vai mexer na configuração do site-loja.
Antes disso, precisamos de um backup:
1. Veja o que ocupa espaço e o que não precisa entrar no backup.
2. Faça um backup compactado do site-loja.
3. Prove que o backup funciona: restaure numa pasta de teste.
4. Guarde uma cópia fora do servidor, com a data no nome.
5. Deixe um jeito fácil de repetir o backup.
EOF
}

criar_entregas() {
  local d="$CURSO/site-entregas"
  mkdir -p "$d/config" "$d/paginas" "$d/docs" "$d/cache" "$CURSO/backups"
  printf 'zona_norte=rota-1\nzona_sul=rota-2\n' > "$d/config/rotas.conf"
  printf 'nome=site-entregas\nporta=80\nambiente=treino\n' > "$d/config/entregas.conf"
  pagina "$d/paginas/index.html" "Entregas de treino"
  pagina "$d/paginas/rastreio.html" "Rastreio"
  printf 'Notas do site-entregas\n- A pasta cache pode ser recriada: não precisa de backup.\n' > "$d/docs/notas.txt"
  # O backup antigo: feito "na semana passada", antes de o arquivo sumir.
  # Se já existe um com esse nome (de outra tentativa), ele é guardado, e não apagado.
  if [ -e "$CURSO/backups/site-entregas-antigo.tar.gz" ]; then
    mkdir -p "$CURSO/backups/guardados-$AGORA"
    mv "$CURSO/backups/site-entregas-antigo.tar.gz" "$CURSO/backups/guardados-$AGORA/" || { echo "Não consegui guardar o backup antigo. Parei aqui."; exit 1; }
    echo "O backup antigo que já existia foi guardado em $CURSO/backups/guardados-$AGORA"
  fi
  ( cd "$CURSO" && tar -czf backups/site-entregas-antigo.tar.gz site-entregas )
  touch -t "$(date -d '7 days ago' +%Y%m%d%H%M 2>/dev/null || date -v-7d +%Y%m%d%H%M)" "$CURSO/backups/site-entregas-antigo.tar.gz"
  # Depois do backup: o cache cresce, a equipe atualiza o rotas.conf (o "trabalho de hoje",
  # que não está no backup antigo) e alguém "apaga" o entregas.conf (ele fica só no backup antigo).
  for n in 1 2; do miniaturas "$d/cache/miniaturas-$n.bin" $((7 * MB)); done
  echo 'zona_leste=rota-3' >> "$d/config/rotas.conf"
  rm -f "$d/config/entregas.conf"
  cat > "$d/CHAMADO.txt" <<'EOF'
CHAMADO #5001 · site-entregas · prioridade alta

Oi! Alguém apagou sem querer o arquivo config/entregas.conf do site-entregas.
Atenção: hoje cedo a equipe atualizou o config/rotas.conf (entrou a zona_leste).
Essa mudança NÃO está no backup antigo, e não pode se perder.

1. O entregas.conf está no backup antigo: ~/curso-linux/backups/site-entregas-antigo.tar.gz
   Restaure esse backup numa pasta de teste, ~/curso-linux/teste-entregas
   (nunca por cima do original!), e copie só o entregas.conf de volta para config/.
2. Faça um backup novo do site-entregas, sem a pasta cache, em ~/curso-linux/backups,
   com a data no nome: site-entregas-AAAA-MM-DD.tar.gz
3. Confira o backup novo: o entregas.conf tem que estar lá dentro, e a cache, não.
4. Para fechar o curso: crie ~/curso-linux/entrega/LEIA-ME.txt e escreva,
   em pelo menos 3 linhas (Enter no fim de cada uma), o que você aprendeu.

Quando terminar, rode estes dois comandos, um de cada vez:
  cd ~/curso-linux
  bash preparar-entrega.sh conferir
EOF
}

guardar() {
  if [ -e "$CURSO/$1" ]; then
    local g="$1-guardada-$AGORA"
    mv "$CURSO/$1" "$CURSO/$g" || { echo "Não consegui guardar a pasta antiga. Não mexi em nada."; exit 1; }
    echo "A pasta antiga foi guardada como $CURSO/$g (nada foi apagado)."
  fi
}

# O backup novo mais recente, com a data no nome.
backup_novo() { ls -t "$CURSO"/backups/site-entregas-20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]*.tar.gz 2>/dev/null | head -n 1; }

case "$OPCAO" in
  "")
    if [ -e "$CURSO/site-loja" ]; then
      echo "A pasta $CURSO/site-loja já existe, então não mexi em nada."
      echo "Para começar do zero: bash preparar-entrega.sh refazer"
      exit 1
    fi
    criar_loja
    echo "Pronto: o site de treino está em $CURSO/site-loja"
    ;;
  refazer)
    if [ -n "$SUB" ] && [ "$SUB" != "missao" ]; then
      echo "Não entendi: refazer $SUB. Não mexi em nada."; uso; exit 1
    fi
    if [ "$SUB" = "missao" ]; then
      # Começa o chamado do zero: guarda tudo o que a tentativa anterior deixou.
      guardar site-entregas; guardar teste-entregas; guardar entrega
      if [ -n "$(backup_novo)" ]; then
        mkdir -p "$CURSO/backups/guardados-$AGORA"
        mv "$CURSO"/backups/site-entregas-20[0-9][0-9]-*.tar.gz "$CURSO/backups/guardados-$AGORA/" || { echo "Não consegui guardar os backups da outra tentativa. Parei aqui."; exit 1; }
        echo "Os backups da outra tentativa foram guardados em $CURSO/backups/guardados-$AGORA"
      fi
      criar_entregas
      echo "Pronto: chamado novo em $CURSO/site-entregas/CHAMADO.txt"
      exit 0
    fi
    guardar site-loja; criar_loja
    echo "Pronto: site de treino novo em $CURSO/site-loja"
    ;;
  missao)
    if [ -e "$CURSO/site-entregas" ]; then
      echo "A pasta $CURSO/site-entregas já existe, então não mexi em nada."
      echo "Para começar o chamado do zero: bash preparar-entrega.sh refazer missao"
      exit 1
    fi
    criar_entregas
    echo "Pronto: o chamado está em $CURSO/site-entregas/CHAMADO.txt"
    ;;
  conferir)
    d="$CURSO/site-entregas"
    if [ ! -d "$d" ]; then echo "Não achei $d. Rode antes: bash preparar-entrega.sh missao"; exit 1; fi
    b="$(backup_novo)"
    ok=0; total=0
    item() { total=$((total + 1)); if eval "$2"; then ok=$((ok + 1)); echo "  [ok]    $1"; else echo "  [falta] $1   → $3"; fi; }
    echo "Conferindo o chamado #5001:"
    item "1. backup antigo restaurado em teste-entregas"       '[ -s "$CURSO/teste-entregas/site-entregas/config/entregas.conf" ]' "mkdir teste-entregas e tar -xzf … -C teste-entregas, na pasta ~/curso-linux"
    item "1. entregas.conf de volta em site-entregas/config"   '[ -s "$d/config/entregas.conf" ]' "copie com o cp, da pasta de teste para site-entregas/config/"
    item "1. o trabalho de hoje continua no rotas.conf"        'grep -q "^zona_leste=" "$d/config/rotas.conf" 2>/dev/null' "a linha zona_leste sumiu: o backup antigo foi por cima do original. Recomece com: bash preparar-entrega.sh refazer missao"
    if [ -z "$b" ]; then
      echo "  [falta] 2 e 3. backup novo   → não achei backups/site-entregas-AAAA-MM-DD.tar.gz (confira o nome e a pasta com ls -lh backups)"
      total=$((total + 3))
    else
      item "2. backup novo com a data no nome, em backups"     'tar -tzf "$b" >/dev/null 2>&1' "o arquivo existe, mas o tar não consegue abrir: faça de novo"
      item "3. o backup novo tem o entregas.conf"              'tar -tzf "$b" 2>/dev/null | grep -q "site-entregas/config/entregas.conf"' "faça o backup de ~/curso-linux, guardando a pasta site-entregas, e depois de copiar o entregas.conf de volta"
      item "3. o backup novo não tem a pasta cache"            '! tar -tzf "$b" 2>/dev/null | grep -q "cache/miniaturas"' "faltou o --exclude='"'"'site-entregas/cache'"'"', antes do -czf e sem barra no fim"
    fi
    item "4. entrega/LEIA-ME.txt com 3 linhas ou mais"         '[ "$(grep -c "[^[:space:]]" "$CURSO/entrega/LEIA-ME.txt" 2>/dev/null | head -n 1)" -ge 3 ] 2>/dev/null' "pasta entrega, arquivo LEIA-ME.txt (maiúsculas), com Enter no fim de cada linha"
    echo "Resultado: $ok de $total."
    if [ "$ok" -eq "$total" ]; then
      echo "Chamado resolvido. Você terminou as missões do curso. Agora, as perguntas finais!"
    else
      echo "Corrija só os itens com [falta] e rode o conferir de novo."
    fi
    ;;
  *)
    echo "Opção desconhecida: $OPCAO"
    uso
    exit 1
    ;;
esac
