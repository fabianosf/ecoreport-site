# 🚀 GUIA DE DEPLOY - EcoReport Site

**Servidor:** 92.113.33.16  
**Domínio:** ecoreport.shop  
**Usuário:** fabianosf / root

---

## ✅ PASSO 1: Código no GitHub

**Status:** ✅ **CONCLUÍDO**

O código já foi enviado para o GitHub:
- Repositório: https://github.com/fabianosf/ecoreport-site
- Branch: main
- Commit: Todas as otimizações incluídas

---

## 📋 PASSO 2: Configurar Servidor

### 2.1 Conectar ao Servidor

```bash
ssh fabianosf@92.113.33.16
# Senha: 123
```

### 2.2 Executar Setup Automático

```bash
# Baixar script de setup
cd /tmp
wget https://raw.githubusercontent.com/fabianosf/ecoreport-site/main/server-setup.sh
chmod +x server-setup.sh
./server-setup.sh
```

**OU fazer manualmente:**

### 2.3 Setup Manual

#### Instalar Node.js 20
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node --version  # Deve mostrar v20.x
```

#### Instalar PM2
```bash
sudo npm install -g pm2
pm2 startup
```

#### Instalar Nginx
```bash
sudo apt update
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

#### Clonar Repositório
```bash
sudo mkdir -p /var/www
cd /var/www
sudo git clone https://github.com/fabianosf/ecoreport-site.git
sudo chown -R fabianosf:fabianosf /var/www/ecoreport-site
cd /var/www/ecoreport-site
```

#### Instalar Dependências
```bash
npm install --production
```

#### Criar .env.local
```bash
nano .env.local
```

Adicione:
```env
# Google Analytics 4
NEXT_PUBLIC_GA_ID=G-FY0M95V3SN

# Site Configuration
NEXT_PUBLIC_SITE_URL=https://ecoreport.shop
GOOGLE_WEBHOOK_URL=https://script.google.com/macros/s/SEU_ID/exec
NODE_ENV=production
```

Salve (Ctrl+O, Enter, Ctrl+X)

#### Build da Aplicação
```bash
npm run build
```

#### Iniciar com PM2
```bash
pm2 start npm --name ecoreport-site -- start
pm2 save
pm2 list  # Verificar se está rodando
```

---

## 🌐 PASSO 3: Configurar Nginx

### 3.1 Criar Configuração

```bash
sudo nano /etc/nginx/sites-available/ecoreport.shop
```

Cole o conteúdo do arquivo `nginx.conf` (já criado no projeto)

### 3.2 Ativar Site

```bash
sudo ln -s /etc/nginx/sites-available/ecoreport.shop /etc/nginx/sites-enabled/
sudo nginx -t  # Testar configuração
sudo systemctl reload nginx
```

---

## 🔒 PASSO 4: Configurar SSL (HTTPS)

### 4.1 Instalar Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### 4.2 Configurar DNS Primeiro

**IMPORTANTE:** Configure DNS antes de gerar SSL:

```
A record: ecoreport.shop → 92.113.33.16
A record: www.ecoreport.shop → 92.113.33.16
```

Aguarde propagação DNS (pode levar algumas horas)

### 4.3 Gerar Certificado SSL

```bash
sudo certbot --nginx -d ecoreport.shop -d www.ecoreport.shop
```

Siga as instruções:
- Email: seu email
- Aceitar termos: Y
- Redirect HTTP → HTTPS: Y

### 4.4 Verificar Renovação Automática

```bash
sudo certbot renew --dry-run
```

---

## ✅ PASSO 5: Verificar Tudo

### 5.1 Verificar Aplicação

```bash
pm2 status
pm2 logs ecoreport-site  # Ver logs
```

### 5.2 Verificar Nginx

```bash
sudo systemctl status nginx
sudo nginx -t
```

### 5.3 Testar Site

```bash
curl http://localhost:3000  # Deve retornar HTML
curl -I https://ecoreport.shop  # Deve retornar 200 OK
```

### 5.4 Verificar SSL

Acesse: https://www.ssllabs.com/ssltest/
- Digite: ecoreport.shop
- Deve mostrar certificado válido

---

## 🔄 PASSO 6: Deploy Futuro (Atualizações)

### Opção A: Deploy Manual

```bash
ssh fabianosf@92.113.33.16
cd /var/www/ecoreport-site
git pull origin main
npm install --production
npm run build
pm2 restart ecoreport-site
```

### Opção B: Script de Deploy

```bash
# No servidor
cd /var/www/ecoreport-site
./deploy.sh
```

---

## 🐛 TROUBLESHOOTING

### Problema: Site não carrega

**Verificar:**
```bash
# 1. PM2 está rodando?
pm2 status

# 2. Nginx está rodando?
sudo systemctl status nginx

# 3. Porta 3000 está aberta?
sudo netstat -tlnp | grep 3000

# 4. Firewall permite?
sudo ufw status
sudo ufw allow 80
sudo ufw allow 443
```

### Problema: SSL não funciona

**Verificar:**
```bash
# 1. DNS está correto?
nslookup ecoreport.shop

# 2. Certificado existe?
sudo ls -la /etc/letsencrypt/live/ecoreport.shop/

# 3. Nginx config está correto?
sudo nginx -t
```

### Problema: Erro 502 Bad Gateway

**Solução:**
```bash
# Verificar se Next.js está rodando
pm2 logs ecoreport-site

# Reiniciar
pm2 restart ecoreport-site
```

---

## 📊 MONITORAMENTO

### Ver Logs

```bash
# Logs da aplicação
pm2 logs ecoreport-site

# Logs do Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Status PM2

```bash
pm2 status
pm2 monit  # Monitor em tempo real
```

---

## ✅ CHECKLIST FINAL

### Servidor
- [ ] Node.js 20 instalado
- [ ] PM2 instalado e configurado
- [ ] Nginx instalado e configurado
- [ ] Repositório clonado
- [ ] Dependências instaladas
- [ ] .env.local configurado
- [ ] Build feito
- [ ] Aplicação rodando no PM2

### DNS
- [ ] A record: ecoreport.shop → 92.113.33.16
- [ ] A record: www.ecoreport.shop → 92.113.33.16
- [ ] DNS propagado (verificar com nslookup)

### SSL/HTTPS
- [ ] Certbot instalado
- [ ] Certificado SSL gerado
- [ ] Nginx configurado para HTTPS
- [ ] HTTP → HTTPS redirect funcionando

### Teste
- [ ] Site acessível em http://ecoreport.shop
- [ ] Site acessível em https://ecoreport.shop
- [ ] Formulário de signup funcionando
- [ ] Google Analytics rastreando

---

## 🎯 RESULTADO ESPERADO

Após completar todos os passos:

✅ Site acessível em: https://ecoreport.shop  
✅ HTTPS funcionando (certificado válido)  
✅ Aplicação rodando 24/7 (PM2)  
✅ Auto-restart em caso de crash  
✅ Logs acessíveis  
✅ Deploy fácil (git pull + restart)  

---

**Guia criado por:** TRAFFIC MASTER OMEGA  
**Última atualização:** ${new Date().toISOString()}  
**Status:** PRODUCTION-READY 🚀

