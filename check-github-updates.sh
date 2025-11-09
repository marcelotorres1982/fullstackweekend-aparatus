#!/bin/bash

# Script para verificar atualizações do repositório upstream
# Repositório: https://github.com/fullstackclubeducacao/fullstackweekend-aparatus

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório do projeto
PROJECT_DIR="/home/marcelo/fsw"
LOG_FILE="$PROJECT_DIR/.update-check.log"
LAST_UPSTREAM_HASH_FILE="$PROJECT_DIR/.last-upstream-hash"

cd "$PROJECT_DIR" || exit 1

echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} Verificando atualizações do repositório upstream..."

# Buscar atualizações do upstream
git fetch upstream main &>/dev/null

if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao buscar atualizações do upstream${NC}"
    exit 1
fi

# Obter o hash atual do upstream/main
CURRENT_UPSTREAM_HASH=$(git rev-parse upstream/main)
CURRENT_LOCAL_HASH=$(git rev-parse HEAD)

# Ler o último hash verificado
if [ -f "$LAST_UPSTREAM_HASH_FILE" ]; then
    LAST_UPSTREAM_HASH=$(cat "$LAST_UPSTREAM_HASH_FILE")
else
    LAST_UPSTREAM_HASH=""
fi

# Verificar se há novos commits
NEW_COMMITS=$(git rev-list HEAD..upstream/main --count)

if [ "$NEW_COMMITS" -gt 0 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🔔 ATUALIZAÇÕES DISPONÍVEIS NO UPSTREAM!${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Há $NEW_COMMITS novo(s) commit(s) disponível(is)${NC}\n"
    
    # Mostrar os commits novos
    echo -e "${BLUE}Commits novos:${NC}"
    git log HEAD..upstream/main --oneline --decorate --color=always
    
    echo ""
    echo -e "${BLUE}Arquivos alterados:${NC}"
    git diff HEAD..upstream/main --stat --color=always
    
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Salvar log
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $NEW_COMMITS novos commits encontrados" >> "$LOG_FILE"
    
    # Salvar o hash atual para referência
    echo "$CURRENT_UPSTREAM_HASH" > "$LAST_UPSTREAM_HASH_FILE"
    
    # Perguntar se deseja atualizar
    echo ""
    read -p "Deseja sincronizar as atualizações agora? (s/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${BLUE}Iniciando sincronização...${NC}"
        
        # Verificar se há mudanças locais não commitadas
        if [[ -n $(git status -s) ]]; then
            echo -e "${YELLOW}⚠️  Você tem mudanças locais não commitadas.${NC}"
            read -p "Deseja fazer stash das mudanças locais? (s/N): " -n 1 -r
            echo ""
            
            if [[ $REPLY =~ ^[Ss]$ ]]; then
                git stash save "Auto-stash antes de merge com upstream em $(date '+%Y-%m-%d %H:%M:%S')"
                echo -e "${GREEN}✓ Mudanças locais salvas em stash${NC}"
            else
                echo -e "${RED}✗ Sincronização cancelada. Commit ou descarte suas mudanças primeiro.${NC}"
                exit 1
            fi
        fi
        
        # Fazer merge do upstream/main
        echo -e "${BLUE}Fazendo merge do upstream/main...${NC}"
        git merge upstream/main --no-edit
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Sincronização concluída com sucesso!${NC}"
            
            # Se havia stash, perguntar se quer aplicá-lo
            if git stash list | grep -q "Auto-stash"; then
                echo ""
                read -p "Deseja reaplicar suas mudanças locais? (s/N): " -n 1 -r
                echo ""
                
                if [[ $REPLY =~ ^[Ss]$ ]]; then
                    git stash pop
                    echo -e "${GREEN}✓ Mudanças locais reaplicadas${NC}"
                fi
            fi
        else
            echo -e "${RED}✗ Erro durante o merge. Resolva os conflitos manualmente.${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}Sincronização adiada. Execute novamente quando quiser atualizar.${NC}"
    fi
else
    echo -e "${GREEN}✓ Seu repositório está atualizado com o upstream${NC}"
    
    # Atualizar o hash de referência
    echo "$CURRENT_UPSTREAM_HASH" > "$LAST_UPSTREAM_HASH_FILE"
fi

echo ""
echo -e "${BLUE}Status atual:${NC}"
echo -e "  Local:    $(git rev-parse --short HEAD)"
echo -e "  Upstream: $(git rev-parse --short upstream/main)"
echo -e "  Origin:   $(git rev-parse --short origin/main)"
