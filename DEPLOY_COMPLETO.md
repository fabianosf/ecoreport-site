# 🚀 DEPLOY COMPLETO - Solução para Erro 404

**Problema:** Site não está acessível, erro 404  
**Solução:** Script completo que configura tudo do zero

---

## ⚡ SOLUÇÃO RÁPIDA (Execute no Servidor)

### Passo 1: Conectar ao Servidor

```bash
ssh fabianosf@92.113.33.16
# Senha: 123
```

### Passo 2: Executar Script Completo

```bash
cd /tmp
wget https://raw.githubusercontent.com/fabianosf/ecoreport-site/main/setup-server-completo.sh
chmod +x setup-server-completo.sh
./setup-server-completo.sh
```

**Este script FAZ TUDO:**
- ✅ Instala Node.js 20 (se não tiver)
- ✅ Instala PM2 (se não tiver)
- ✅ Instala Nginx (se não tiver)
- ✅ Clona/atualiza repositório
- ✅ Instala dependências
- ✅ Cria .env.local
- ✅ Faz build da aplicação
- ✅ Inicia com PM2
- ✅ Configura Nginx
- ✅ Testa tudo

---

## 🐛 SE AINDA NÃO FUNCIONAR

### 1. Verificar se PM2 está rodando

```bash
pm2 status
```

Se não estiver:

```bash
cd /var/www/ecoreport-site
pm2 start npm --name ecoreport-site -- start
pm2 save
pm2 logs ecoreport-site
```

### 2. Verificar se porta 3000 está aberta

```bash
netstat -tlnp | grep :3000
# ou
ss -tlnp | grep :3000
```

Se não estiver:

```bash
cd /var/www/ecoreport-site
npm run build
pm2 restart ecoreport-site
```

### 3. Verificar configuração do Nginx

```bash
sudo cat /etc/nginx/sites-available/ecoreport.shop
```

Deve conter:

```nginx
server {
    listen 80;
    server_name ecoreport.shop www.ecoreport.shop;

    location / {
        proxy_pass http://localhost:3000;
        ...
    }
}
```

Se não estiver correto:

```bash
sudo nano /etc/nginx/sites-available/ecoreport.shop
# Cole a configuração acima
sudo nginx -t
sudo systemctl reload nginx
```

### 4. Verificar se site está ativado no Nginx

```bash
sudo ls -la /etc/nginx/sites-enabled/ | grep ecoreport
```

Se não estiver:

```bash
sudo ln -s /etc/nginx/sites-available/ecoreport.shop /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 5. Verificar logs

```bash
# Logs do PM2
pm2 logs ecoreport-site --lines 50

# Logs do Nginx
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### 6. Testar localmente

```bash
# Testar Next.js diretamente
curl http://localhost:3000 | head -20

# Testar via Nginx
curl http://localhost | head -20

# Testar via domínio
curl -I http://ecoreport.shop
```

---

## ✅ VERIFICAÇÃO PASSO A PASSO

Execute cada comando e verifique a saída:

### 1. PM2 está rodando?

```bash
pm2 status
```

**Deve mostrar:** `ecoreport-site | online`

### 2. Porta 3000 está ativa?

```bash
netstat -tlnp | grep :3000
```

**Deve mostrar:** `tcp 0 0 127.0.0.1:3000`

### 3. Aplicação responde localmente?

```bash
curl -I http://localhost:3000
```

**Deve retornar:** `HTTP/1.1 200 OK`

### 4. Nginx está rodando?

```bash
sudo systemctl status nginx
```

**Deve mostrar:** `active (running)`

### 5. Nginx está configurado?

```bash
sudo nginx -t
```

**Deve mostrar:** `syntax is ok` e `test is successful`

### 6. Site está ativado?

```bash
sudo ls -la /etc/nginx/sites-enabled/ | grep ecoreport
```

**Deve mostrar:** `ecoreport.shop -> ...`

### 7. DNS está configurado?

```bash
nslookup ecoreport.shop
```

**Deve mostrar:** `92.113.33.16`

---

## 🔧 COMANDOS ÚTEIS

### Reiniciar tudo

```bash
cd /var/www/ecoreport-site
pm2 restart ecoreport-site
sudo systemctl restart nginx
```

### Ver tudo de uma vez

```bash
echo "=== PM2 ===" && pm2 status && \
echo "=== Porta 3000 ===" && netstat -tlnp | grep :3000 && \
echo "=== Nginx ===" && sudo systemctl status nginx --no-pager | head -3 && \
echo "=== Teste Local ===" && curl -I http://localhost:3000 2>&1 | head -1
```

### Limpar e recomeçar

```bash
cd /var/www/ecoreport-site
pm2 delete ecoreport-site
npm run build
pm2 start npm --name ecoreport-site -- start
pm2 save
```

---

## 📊 O QUE O SCRIPT FAZ

1. ✅ Instala Node.js 20
2. ✅ Instala PM2
3. ✅ Instala Nginx
4. ✅ Clona repositório (ou atualiza)
5. ✅ Instala dependências
6. ✅ Cria .env.local
7. ✅ Faz build
8. ✅ Inicia com PM2
9. ✅ Configura Nginx
10. ✅ Testa tudo
11. ✅ Verifica firewall

---

## 🎯 RESULTADO ESPERADO

Após executar `setup-server-completo.sh`:

✅ Site acessível em: http://ecoreport.shop  
✅ Next.js rodando na porta 3000  
✅ PM2 gerenciando aplicação  
✅ Nginx fazendo proxy  
✅ Sem erro 404  

---

**Execute:** `./setup-server-completo.sh` no servidor! 🚀

