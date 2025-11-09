#!/bin/bash

# Script para configurar verificação automática de atualizações

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="/home/marcelo/fsw"
SERVICE_FILE="$HOME/.config/systemd/user/fsw-update-check.service"
TIMER_FILE="$HOME/.config/systemd/user/fsw-update-check.timer"

echo -e "${BLUE}Configurando verificação automática de atualizações...${NC}\n"

# Criar diretório para serviços do usuário se não existir
mkdir -p "$HOME/.config/systemd/user"

# Tornar o script executável
chmod +x "$PROJECT_DIR/check-github-updates.sh"

# Criar arquivo de serviço
echo -e "${YELLOW}Criando serviço systemd...${NC}"
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Verificar atualizações do repositório FSW upstream
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/bin/bash -c 'cd $PROJECT_DIR && ./check-github-updates.sh | tee -a .update-check.log && if [ \$(git rev-list HEAD..upstream/main --count) -gt 0 ]; then notify-send "FSW: Atualizações Disponíveis" "Há novos commits no repositório upstream. Execute ./check-github-updates.sh para sincronizar." -u normal -i software-update-available; fi'
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

# Criar arquivo de timer
echo -e "${YELLOW}Criando timer (execução de hora em hora)...${NC}"
cat > "$TIMER_FILE" << EOF
[Unit]
Description=Timer para verificar atualizações do FSW a cada hora
Requires=fsw-update-check.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Recarregar systemd
echo -e "${YELLOW}Recarregando systemd...${NC}"
systemctl --user daemon-reload

# Habilitar e iniciar o timer
echo -e "${YELLOW}Habilitando e iniciando o timer...${NC}"
systemctl --user enable fsw-update-check.timer
systemctl --user start fsw-update-check.timer

echo ""
echo -e "${GREEN}✓ Configuração concluída!${NC}\n"
echo -e "${BLUE}Comandos úteis:${NC}"
echo "  Ver status do timer:       systemctl --user status fsw-update-check.timer"
echo "  Ver logs:                  journalctl --user -u fsw-update-check.service -f"
echo "  Parar verificação:         systemctl --user stop fsw-update-check.timer"
echo "  Desabilitar verificação:   systemctl --user disable fsw-update-check.timer"
echo "  Executar verificação agora: systemctl --user start fsw-update-check.service"
echo "  Ver arquivo de log local:  tail -f $PROJECT_DIR/.update-check.log"
echo ""
echo -e "${YELLOW}O sistema verificará atualizações:${NC}"
echo "  - 5 minutos após o boot"
echo "  - A cada 1 hora após isso"
echo "  - Você receberá notificações quando houver atualizações"
echo ""
echo -e "${GREEN}Para executar a verificação manualmente agora:${NC}"
echo "  cd $PROJECT_DIR && ./check-github-updates.sh"
