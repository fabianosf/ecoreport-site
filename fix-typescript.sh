#!/bin/bash

# Script para corrigir instalação do TypeScript no servidor
# Execute este script NO SERVIDOR

set -e

APP_DIR="/var/www/ecoreport-site"

echo "🔧 Corrigindo instalação do TypeScript..."

cd ${APP_DIR}

# Limpar node_modules e package-lock.json para garantir instalação limpa
echo "🧹 Limpando instalação anterior..."
rm -rf node_modules package-lock.json

# Garantir que NODE_ENV não está definido como production durante instalação
unset NODE_ENV

# Instalar todas as dependências (incluindo devDependencies)
echo "📦 Instalando todas as dependências..."
npm install

# Verificar se TypeScript foi instalado
if [ -d "node_modules/typescript" ]; then
    echo "✅ TypeScript instalado com sucesso!"
    echo "📊 Versão: $(node_modules/.bin/tsc --version 2>/dev/null || echo 'verificando...')"
else
    echo "❌ TypeScript ainda não encontrado. Instalando manualmente..."
    npm install --save-dev typescript
fi

# Verificar instalação
echo "🔍 Verificando instalação..."
if [ -f "node_modules/typescript/package.json" ]; then
    echo "✅ TypeScript confirmado em node_modules/typescript"
else
    echo "❌ Erro: TypeScript não encontrado após instalação"
    exit 1
fi

echo "✅ Correção concluída! Agora execute: npm run build"
