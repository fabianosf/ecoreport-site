# 🚀 Instruções de Deploy - EcoReport Site

## ✅ Status
- ✅ Build local verificado e funcionando
- ✅ Código enviado para GitHub
- ✅ Scripts de deploy criados e disponíveis

---

## 📋 DEPLOY NO SERVIDOR (92.113.33.16)

### Opção 1: Deploy Automático (Recomendado)

1. **Conecte-se ao servidor:**
   ```bash
   ssh fabianosf@92.113.33.16
   # Digite a senha quando solicitado
   ```

2. **Execute o script de deploy:**
   ```bash
   cd /tmp
   wget https://raw.githubusercontent.com/fabianosf/ecoreport-site/main/deploy-automatico.sh
   chmod +x deploy-automatico.sh
   
   # Se precisar usar token do GitHub (opcional):
   export GITHUB_TOKEN="seu_token_aqui"
   
   ./deploy-automatico.sh
   ```

### Opção 2: Deploy Manual Passo a Passo

Se o script automático não funcionar, siga estes passos:

```bash
# 1. Conectar ao servidor
ssh fabianosf@92.113.33.16

# 2. Instalar Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# 3. Instalar PM2
sudo npm install -g pm2
pm2 startup

# 4. Instalar Nginx
sudo apt update
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# 5. Clonar repositório
sudo mkdir -p /var/www
cd /var/www
sudo git clone https://github.com/fabianosf/ecoreport-site.git
sudo chown -R fabianosf:fabianosf /var/www/ecoreport-site
cd /var/www/ecoreport-site

# 6. Criar .env.local
nano .env.local
# Cole este conteúdo:
# NEXT_PUBLIC_GA_ID=G-FY0M95V3SN
# NEXT_PUBLIC_SITE_URL=https://ecoreport.shop
# GOOGLE_WEBHOOK_URL=https://script.google.com/macros/s/SEU_ID/exec
# NODE_ENV=production

# 7. Instalar dependências e build
npm install
npm run build

# 8. Iniciar com PM2
pm2 start npm --name ecoreport-site -- start
pm2 save

# 9. Configurar Nginx
sudo cp /var/www/ecoreport-site/nginx.conf /etc/nginx/sites-available/ecoreport.shop
sudo ln -s /etc/nginx/sites-available/ecoreport.shop /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔍 VERIFICAÇÃO

Após o deploy, verifique:

```bash
# Status do PM2
pm2 status

# Logs da aplicação
pm2 logs ecoreport-site

# Testar localmente
curl http://localhost:3000

# Status do Nginx
sudo systemctl status nginx
```

---

## 🌐 ACESSAR O SITE

- **IP direto:** http://92.113.33.16
- **Domínio (após DNS):** http://ecoreport.shop

---

## 🔒 CONFIGURAR SSL (HTTPS)

Após configurar o DNS (ecoreport.shop → 92.113.33.16):

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d ecoreport.shop -d www.ecoreport.shop
```

---

## 🔄 ATUALIZAR DEPLOY (Depois)

Para atualizar o site no futuro:

```bash
ssh fabianosf@92.113.33.16
cd /var/www/ecoreport-site
git pull origin main
npm install
npm run build
pm2 restart ecoreport-site
```

---

## 🐛 PROBLEMAS COMUNS

### Site não carrega
```bash
pm2 logs ecoreport-site
pm2 restart ecoreport-site
```

### Erro 502 Bad Gateway
```bash
pm2 status
sudo netstat -tlnp | grep 3000
sudo systemctl restart nginx
```

### Git pede senha
```bash
# Configurar credenciais
git config --global credential.helper store
# Ou usar token (substitua SEU_TOKEN pelo token real):
git remote set-url origin https://SEU_TOKEN@github.com/fabianosf/ecoreport-site.git
```

---

## 📝 NOTAS

- **Servidor:** 92.113.33.16
- **Usuário:** fabianosf
- **Nota:** Mantenha suas credenciais seguras e não as compartilhe publicamente

---

**✅ Tudo pronto para deploy!** 🚀
