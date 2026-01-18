# 🔧 CORRIGIR ERRO 404 - Nginx

**Problema:** Erro 404 do Nginx no domínio ecoreport.shop  
**Solução:** Configurar Nginx para fazer proxy para Next.js

---

## 🚀 SOLUÇÃO RÁPIDA

### Conectar ao Servidor

```bash
ssh fabianosf@92.113.33.16
# Senha: 123
```

### Executar Script de Correção

```bash
cd /tmp
wget https://raw.githubusercontent.com/fabianosf/ecoreport-site/main/fix-nginx.sh
chmod +x fix-nginx.sh
./fix-nginx.sh
```

---

## 📋 SOLUÇÃO MANUAL

### PASSO 1: Verificar se Next.js está rodando

```bash
pm2 status
```

Se não estiver rodando:

```bash
cd /var/www/ecoreport-site
pm2 start npm --name ecoreport-site -- start
pm2 save
```

### PASSO 2: Verificar porta 3000

```bash
netstat -tlnp | grep :3000
```

Deve mostrar algo como: `tcp 0 0 127.0.0.1:3000`

### PASSO 3: Criar configuração Nginx

```bash
sudo nano /etc/nginx/sites-available/ecoreport.shop
```

Cole este conteúdo:

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

### PASSO 4: Ativar site

```bash
sudo ln -s /etc/nginx/sites-available/ecoreport.shop /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
```

### PASSO 5: Testar e recarregar

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### PASSO 6: Verificar

```bash
curl -I http://localhost:3000
curl -I http://ecoreport.shop
```

---

## 🐛 TROUBLESHOOTING

### Problema: PM2 não está rodando

```bash
cd /var/www/ecoreport-site
npm install --production
npm run build
pm2 start npm --name ecoreport-site -- start
pm2 save
```

### Problema: Porta 3000 não está aberta

```bash
# Verificar se Next.js está rodando
pm2 status

# Reiniciar
pm2 restart ecoreport-site

# Ver logs
pm2 logs ecoreport-site
```

### Problema: Nginx não recarrega

```bash
# Verificar erro
sudo nginx -t

# Ver logs
sudo tail -f /var/log/nginx/error.log

# Reiniciar
sudo systemctl restart nginx
```

### Problema: Firewall bloqueando

```bash
# Verificar status
sudo ufw status

# Permitir HTTP
sudo ufw allow 80
sudo ufw allow 443

# Recarregar
sudo ufw reload
```

---

## ✅ VERIFICAÇÃO FINAL

### 1. PM2 está rodando?

```bash
pm2 status
```

Deve mostrar `ecoreport-site` como `online`

### 2. Porta 3000 está aberta?

```bash
netstat -tlnp | grep :3000
```

Deve mostrar processo ouvindo na porta 3000

### 3. Nginx está rodando?

```bash
sudo systemctl status nginx
```

Deve mostrar `active (running)`

### 4. Site responde localmente?

```bash
curl http://localhost:3000 | head -20
```

Deve retornar HTML do site

### 5. Site responde via domínio?

```bash
curl -I http://ecoreport.shop
```

Deve retornar `200 OK`

---

## 🎯 RESULTADO ESPERADO

Após executar os passos:

✅ Site acessível em: http://ecoreport.shop  
✅ Nginx fazendo proxy para Next.js (porta 3000)  
✅ Aplicação rodando no PM2  
✅ Sem erro 404  

---

**Status:** Script criado, pronto para uso no servidor! 🚀

