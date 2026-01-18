# ⚡ SOLUÇÃO RÁPIDA - Erro 404 Nginx

**Problema:** Site ainda mostra 404 do Nginx  
**Solução:** Script rápido que corrige em 30 segundos

---

## 🚀 SOLUÇÃO RÁPIDA (3 Passos)

### PASSO 1: Conectar ao Servidor

```bash
ssh fabianosf@92.113.33.16
# Senha: 123
```

### PASSO 2: Baixar e Executar Script

```bash
cd /tmp
wget https://raw.githubusercontent.com/fabianosf/ecoreport-site/main/quick-fix.sh
chmod +x quick-fix.sh
./quick-fix.sh
```

### PASSO 3: Verificar

```bash
curl -I http://ecoreport.shop
```

**Deve retornar:** `HTTP/1.1 200 OK`

---

## 📋 SE NÃO TIVER O PROJETO NO SERVIDOR

Execute primeiro:

```bash
# 1. Criar diretório
sudo mkdir -p /var/www/ecoreport-site
sudo chown -R $USER:$USER /var/www/ecoreport-site

# 2. Clonar repositório
cd /var/www
git clone https://github.com/fabianosf/ecoreport-site.git
cd ecoreport-site

# 3. Criar .env.local
nano .env.local
```

Cole:
```env
NEXT_PUBLIC_GA_ID=G-FY0M95V3SN
NEXT_PUBLIC_SITE_URL=https://ecoreport.shop
GOOGLE_WEBHOOK_URL=https://script.google.com/macros/s/SEU_ID/exec
NODE_ENV=production
```

Salve (Ctrl+O, Enter, Ctrl+X)

# 4. Executar script
chmod +x quick-fix.sh
./quick-fix.sh

---

## 🔧 SOLUÇÃO MANUAL (Se Script Não Funcionar)

### 1. Verificar se Next.js está rodando

```bash
pm2 status
```

Se não estiver:

```bash
cd /var/www/ecoreport-site
npm install
npm run build
pm2 start npm --name ecoreport-site -- start
pm2 save
```

### 2. Verificar porta 3000

```bash
netstat -tlnp | grep :3000
```

**Deve mostrar:** `tcp 0 0 127.0.0.1:3000`

### 3. Testar localmente

```bash
curl http://localhost:3000 | head -10
```

**Deve mostrar:** HTML do site

### 4. Configurar Nginx

```bash
sudo nano /etc/nginx/sites-available/ecoreport.shop
```

Cole:
```nginx
server {
    listen 80;
    server_name ecoreport.shop www.ecoreport.shop;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Salve (Ctrl+O, Enter, Ctrl+X)

### 5. Ativar e recarregar

```bash
sudo ln -s /etc/nginx/sites-available/ecoreport.shop /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

### 6. Testar

```bash
curl -I http://ecoreport.shop
```

---

## 🐛 TROUBLESHOOTING

### PM2 não está rodando

```bash
cd /var/www/ecoreport-site
pm2 logs ecoreport-site
pm2 restart ecoreport-site
```

### Porta 3000 não está aberta

```bash
# Verificar logs
pm2 logs ecoreport-site --lines 50

# Reiniciar
pm2 restart ecoreport-site
```

### Nginx não funciona

```bash
# Verificar configuração
sudo nginx -t

# Ver logs
sudo tail -f /var/log/nginx/error.log
```

### Teste rápido tudo junto

```bash
echo "PM2:" && pm2 status && \
echo "Porta 3000:" && (netstat -tlnp | grep :3000 || ss -tlnp | grep :3000) && \
echo "Teste local:" && curl -I http://localhost:3000 2>&1 | head -1
```

---

**Execute o script `quick-fix.sh` no servidor!** 🚀

