# 🚀 Deploy Manual - EcoReport Site

## Servidor: 92.113.33.16
## Usuário: fabianosf

---

## 📋 PASSO A PASSO

### 1. Conectar ao Servidor

```bash
ssh fabianosf@92.113.33.16
# Digite a senha quando solicitado
```

### 2. Executar o Script de Deploy

Depois de conectar, execute:

```bash
cd /tmp
wget https://raw.githubusercontent.com/fabianosf/ecoreport-site/main/deploy-automatico.sh
# OU se wget não funcionar:
curl -o deploy-automatico.sh https://raw.githubusercontent.com/fabianosf/ecoreport-site/main/deploy-automatico.sh

chmod +x deploy-automatico.sh
./deploy-automatico.sh
```

**OU** copie o script manualmente:

1. No seu computador local, copie o conteúdo de `deploy-automatico.sh`
2. No servidor, crie o arquivo:
   ```bash
   nano /tmp/deploy-automatico.sh
   ```
3. Cole o conteúdo, salve (Ctrl+O, Enter, Ctrl+X)
4. Execute:
   ```bash
   chmod +x /tmp/deploy-automatico.sh
   /tmp/deploy-automatico.sh
   ```

---

## ✅ O QUE O SCRIPT FAZ

1. ✅ Instala Node.js 20 (se não tiver)
2. ✅ Instala PM2 (se não tiver)
3. ✅ Instala Nginx (se não tiver)
4. ✅ Clona/atualiza o repositório do GitHub
5. ✅ Instala dependências npm
6. ✅ Faz build da aplicação
7. ✅ Configura PM2 para rodar a aplicação
8. ✅ Configura Nginx como proxy reverso

---

## 🔍 VERIFICAÇÃO

Após o deploy, verifique:

```bash
# Ver status do PM2
pm2 status

# Ver logs
pm2 logs ecoreport-site

# Testar aplicação
curl http://localhost:3000

# Verificar Nginx
sudo systemctl status nginx
```

---

## 🌐 ACESSAR O SITE

- **IP direto:** http://92.113.33.16
- **Domínio (após configurar DNS):** http://ecoreport.shop

---

## 🔒 CONFIGURAR SSL (HTTPS)

Após configurar o DNS:

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d ecoreport.shop -d www.ecoreport.shop
```

---

## 📝 EDITAR .env.local

```bash
nano /var/www/ecoreport-site/.env.local
```

Adicione o `GOOGLE_WEBHOOK_URL` real e reinicie:

```bash
pm2 restart ecoreport-site
```

---

## 🐛 PROBLEMAS?

### Site não carrega
```bash
pm2 logs ecoreport-site
pm2 restart ecoreport-site
```

### Erro 502
```bash
pm2 status
sudo netstat -tlnp | grep 3000
```

### Nginx não funciona
```bash
sudo nginx -t
sudo systemctl restart nginx
sudo tail -f /var/log/nginx/error.log
```
