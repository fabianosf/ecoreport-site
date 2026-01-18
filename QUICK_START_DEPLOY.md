# ⚡ QUICK START - Deploy Rápido

**Servidor:** 92.113.33.16  
**Domínio:** ecoreport.shop

---

## 🚀 DEPLOY RÁPIDO (3 Passos)

### PASSO 1: Conectar ao Servidor

```bash
ssh fabianosf@92.113.33.16
# Senha: 123
```

### PASSO 2: Executar Setup (Primeira Vez)

```bash
# Baixar e executar script de setup
cd /tmp
wget https://raw.githubusercontent.com/fabianosf/ecoreport-site/main/server-setup.sh
chmod +x server-setup.sh
./server-setup.sh
```

**OU fazer manualmente:**

```bash
# 1. Instalar Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# 2. Instalar PM2
sudo npm install -g pm2

# 3. Instalar Nginx
sudo apt install -y nginx

# 4. Clonar repositório
sudo mkdir -p /var/www
cd /var/www
sudo git clone https://github.com/fabianosf/ecoreport-site.git
sudo chown -R fabianosf:fabianosf /var/www/ecoreport-site
cd /var/www/ecoreport-site

# 5. Instalar dependências
npm install --production

# 6. Criar .env.local
nano .env.local
# Cole o conteúdo (veja abaixo)

# 7. Build
npm run build

# 8. Iniciar com PM2
pm2 start npm --name ecoreport-site -- start
pm2 save
```

### PASSO 3: Configurar Nginx e SSL

```bash
# 1. Copiar configuração Nginx
sudo cp /var/www/ecoreport-site/nginx.conf /etc/nginx/sites-available/ecoreport.shop

# 2. Ativar site
sudo ln -s /etc/nginx/sites-available/ecoreport.shop /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# 3. Configurar DNS (no seu provedor de domínio)
# A record: ecoreport.shop → 92.113.33.16
# A record: www.ecoreport.shop → 92.113.33.16

# 4. Aguardar propagação DNS (algumas horas)

# 5. Instalar SSL
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d ecoreport.shop -d www.ecoreport.shop
```

---

## 📝 CONTEÚDO DO .env.local

Crie o arquivo `/var/www/ecoreport-site/.env.local`:

```env
# Google Analytics 4
NEXT_PUBLIC_GA_ID=G-FY0M95V3SN

# Site Configuration
NEXT_PUBLIC_SITE_URL=https://ecoreport.shop
GOOGLE_WEBHOOK_URL=https://script.google.com/macros/s/SEU_ID/exec
NODE_ENV=production
```

⚠️ **IMPORTANTE:** Substitua `SEU_ID` pelo ID real do Google Sheets webhook!

---

## 🔄 DEPLOY DE ATUALIZAÇÕES (Depois)

### Opção A: Deploy Remoto Automático (Do seu computador)

```bash
# No seu computador local
cd /home/fabianosf/Desktop/ecoreport-site
./remote-deploy.sh
```

### Opção B: Deploy Manual (No servidor)

```bash
ssh fabianosf@92.113.33.16
cd /var/www/ecoreport-site
git pull origin main
npm install --production
npm run build
pm2 restart ecoreport-site
```

---

## ✅ VERIFICAÇÃO

### Verificar se está funcionando:

```bash
# 1. PM2
pm2 status

# 2. Nginx
sudo systemctl status nginx

# 3. Site
curl http://localhost:3000
curl -I https://ecoreport.shop
```

### Acessar no navegador:

- http://ecoreport.shop (deve redirecionar para HTTPS)
- https://ecoreport.shop (deve carregar o site)

---

## 🐛 PROBLEMAS COMUNS

### Site não carrega

```bash
# Verificar PM2
pm2 logs ecoreport-site

# Reiniciar
pm2 restart ecoreport-site
```

### Erro 502 Bad Gateway

```bash
# Verificar se Next.js está rodando
pm2 status

# Verificar porta 3000
sudo netstat -tlnp | grep 3000
```

### SSL não funciona

```bash
# Verificar DNS
nslookup ecoreport.shop

# Verificar certificado
sudo certbot certificates
```

---

## 📊 COMANDOS ÚTEIS

```bash
# Ver logs em tempo real
pm2 logs ecoreport-site

# Reiniciar aplicação
pm2 restart ecoreport-site

# Ver status
pm2 status

# Ver logs do Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

---

**Status:** ✅ Código no GitHub, scripts prontos para deploy! 🚀

