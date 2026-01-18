# 🚀 GUIA DE SETUP DE CAMPANHAS - EcoReport

**Criado por:** TRAFFIC MASTER OMEGA  
**Objetivo:** Passo a passo para criar campanhas no Facebook Ads e Google Ads

---

## 📱 FACEBOOK ADS - SETUP COMPLETO

### PASSO 1: Criar Campanha Cold Audience

#### 1.1 Acesse Facebook Ads Manager
- URL: https://business.facebook.com/adsmanager
- Clique em: **Criar** → **Campanha**

#### 1.2 Configurar Objetivo
- **Objetivo:** Alcance + Tráfego
- **Nome da Campanha:** `EcoReport - Cold Audience - Awareness`
- **Status:** Ativa
- **Orçamento:** R$ 1.200/mês (ou 40% do total)

#### 1.3 Configurar Conjunto de Anúncios
- **Nome:** `Cold - Feed + Instagram`
- **Otimização:** Cliques no link
- **Orçamento:** R$ 40/dia

#### 1.4 Configurar Audiência

**Nova Audiência Personalizada:**

```
Nome: "Brasil - Gestão Fiscal - 25-55"

LOCALIZAÇÃO:
✅ Incluir: Brasil
✅ Pessoas que vivem nesta localização

IDADE: 25 a 55 anos

SEXO: Todos

DETALHAMENTOS:
Gênero: Todos
Idade: 25-55

INTERESSES (adicionar):
- Gestão empresarial
- Contabilidade
- Empreendedorismo
- Software empresarial
- Nota fiscal eletrônica
- PIX (sistema de pagamento)
- Pequenas e médias empresas

COMPORTAMENTOS:
- Comprador online (últimos 90 dias)
- Tech enthusiast
- Pequeno empresário
- Usuário de smartphone

CONEXÕES:
- Todas as pessoas (sem restrição)
```

**Tamanho estimado:** 500.000 - 2.000.000 pessoas

#### 1.5 Configurar Colocação
- ✅ Feed do Facebook
- ✅ Stories do Facebook
- ✅ Feed do Instagram
- ✅ Stories do Instagram
- ❌ Reels (desabilitar inicialmente)
- ❌ Messenger (desabilitar inicialmente)

#### 1.6 Configurar Orçamento e Lances
- **Estratégia de lançamento:** Custo mínimo por clique no link
- **Orçamento:** R$ 40/dia
- **Agendamento:** Contínuo

#### 1.7 Criar Anúncios (3-5 variações)

**Anúncio 1: Imagem**
```
Formato: Imagem única
Imagem: 1200x628px (dashboard EcoReport)
Texto primário: "Pare de se perder em planilhas fiscais. EcoReport centraliza NFCe, pedidos e PIX em um dashboard inteligente. Comece grátis por 30 dias."
Headline: "Gestão Fiscal Completa em Um Só Lugar"
Descrição: "10.000+ empresas confiam. Teste sem cartão de crédito."
Botão: "Saber Mais"
```

**Anúncio 2: Vídeo (15-30s)**
```
Formato: Vídeo
Vídeo: Demo EcoReport (15-30 segundos)
Texto primário: "Dashboard que organiza gestão fiscal em 5 minutos. Veja como funciona."
Headline: "EcoReport: Gestão Fiscal Simplificada"
Descrição: "Teste grátis por 30 dias"
Botão: "Assistir Vídeo" → depois muda para "Começar Grátis"
```

**Anúncio 3: Carousel (5 cards)**
```
Formato: Carousel
Card 1: Headline + Dashboard
Card 2: Benefício NFCe
Card 3: Benefício Pedidos
Card 4: Benefício PIX
Card 5: CTA + Preço
```

#### 1.8 Link e Landing Page
- **Link:** `https://ecoreport.app` (ou landing page específica)
- **Parâmetros UTM:**
  - `utm_source=facebook`
  - `utm_medium=cpc`
  - `utm_campaign=cold_awareness`

#### 1.9 Revisar e Publicar
- ✅ Revisar todas as configurações
- ✅ Publicar campanha
- ⏰ Aguardar aprovação (1-24 horas)

---

### PASSO 2: Criar Campanha Retargeting (Warm)

#### 2.1 Criar Nova Campanha
- **Objetivo:** Conversões
- **Nome:** `EcoReport - Warm - Retargeting`
- **Orçamento:** R$ 900/mês (30% do total)

#### 2.2 Configurar Audiência (Custom Audience)

**Opção A: Pixel de Site**
```
Tipo: Personalizada → Tráfego do site
Tipo de tráfego: Todos os visitantes
Período: Últimos 30 dias
Nome: "Visitantes Site - 30 dias"
```

**Opção B: Excluir Convertidos**
```
Criar audiência de exclusão:
Tipo: Personalizada → Tráfego do site
Tipo de tráfego: Todos os visitantes
Evento: Lead/Signup
Período: Últimos 30 dias
Nome: "Convertidos - Excluir"
```

#### 2.3 Anúncios de Retargeting

```
Texto primário: "Você visitou o EcoReport. Que tal começar hoje? 10.000+ empresas já transformaram sua gestão fiscal."

Headline: "Complete Seu Cadastro - 30 Dias Grátis"
Descrição: "Sem cartão de crédito. Cancele quando quiser."
Botão: "Finalizar Cadastro Agora"
```

---

### PASSO 3: Criar Campanha Lookalike (Hot)

#### 3.1 Criar Audiência Lookalike

**Fonte (se tiver convertidos):**
```
Tipo: Lookalike
Origem: Audiência de conversões (Lead/Signup)
Localização: Brasil
Semelhança: 1% (mais similar)
Nome: "Lookalike Convertidos 1%"
```

#### 3.2 Campanha Lookalike
- **Objetivo:** Conversões
- **Orçamento:** R$ 600/mês (20% do total)
- **Audiência:** Lookalike 1%
- **Otimização:** Eventos de conversão (Signup)

---

## 🔍 GOOGLE ADS - SETUP COMPLETO

### PASSO 1: Criar Campanha Search

#### 1.1 Acesse Google Ads
- URL: https://ads.google.com
- Clique em: **Campanhas** → **Nova campanha**

#### 1.2 Escolher Objetivo
- **Objetivo:** Vendas
- **Tipo:** Pesquisa
- **Nome:** `EcoReport - Search - Gestão Fiscal`

#### 1.3 Configurações da Campanha
- **Redes:** Apenas Google Search (desabilitar Rede de Pesquisa de Parceiros)
- **Localizações:** Brasil
- **Idiomas:** Português
- **Orçamento:** R$ 29/dia (R$ 875/mês)

#### 1.4 Criar Grupo de Anúncios

**Grupo 1: Software Gestão Fiscal**

**Palavras-chave (Correspondência Exata):**
```
[software gestão fiscal]
[software controle pedidos]
[emissão nota fiscal online]
[sistema gestão fiscal brasil]
[plataforma gestão financeira]
```

**Palavras-chave (Correspondência de Frase):**
```
"software gestão fiscal"
"emissão nota fiscal eletrônica"
"sistema controle pedidos empresa"
"gerenciar pagamentos pix empresa"
```

**Palavras-chave (Correspondência Ampla Modificada):**
```
+software +gestão +fiscal
+emissão +nota +fiscal
+controle +pedidos +online
+gerenciamento +pix +empresa
```

#### 1.5 Criar Anúncios (3 variações)

**Anúncio 1:**
```
Título 1: Software Gestão Fiscal | EcoReport
Título 2: NFCe + Pedidos + PIX | 30 Dias Grátis
Título 3: Comece Agora | Sem Cartão

Descrição 1: Plataforma completa de gestão fiscal brasileira. Emissão NFCe automática, controle de pedidos e pagamentos PIX integrados.

Descrição 2: 10.000+ empresas confiam. Dashboard inteligente, relatórios avançados. Teste 30 dias grátis sem compromisso.

Caminhos: ecoreport.app/comecar | Gestão Fiscal
```

**Anúncio 2:**
```
Título 1: Gestão Fiscal Completa | EcoReport
Título 2: 1000 NFCes/mês | R$ 149/mês
Título 3: Teste Grátis | Sem Compromisso

Descrição 1: Emita notas fiscais eletrônicas sem erros. Sistema integrado com SEFAZ, validação automática, dashboard em tempo real.

Descrição 2: Controle total de NFCes, pedidos e PIX. Histórico completo, relatórios fiscais. Comece hoje grátis por 30 dias.

Caminhos: ecoreport.app/planos | NFCe | Preços
```

**Anúncio 3:**
```
Título 1: EcoReport | Gestão Fiscal Simplificada
Título 2: Dashboard Inteligente | Teste 30 Dias
Título 3: Sem Cartão | Cancele Quando Quiser

Descrição 1: Centralize notas fiscais, pedidos e pagamentos PIX. Tudo automatizado, sem planilhas, sem dor de cabeça.

Descrição 2: Economize 10h/semana em burocracia fiscal. 10.000+ empresas aumentaram eficiência em 40%. Teste grátis.

Caminhos: ecoreport.app | Como Funciona | Demo
```

#### 1.6 Extensões de Anúncio
- **Extensão de site:** Adicionar links importantes
  - Planos e Preços
  - Como Funciona
  - Recursos
- **Extensão de callout:**
  - "30 dias grátis"
  - "Sem cartão de crédito"
  - "10.000+ empresas"
  - "Suporte em português"

---

### PASSO 2: Criar Campanha Display Remarketing

#### 2.1 Criar Nova Campanha
- **Tipo:** Display
- **Objetivo:** Vendas
- **Nome:** `EcoReport - Display - Remarketing`

#### 2.2 Criar Audiência de Remarketing
```
Tipo: Público personalizado
Fonte: Lista de visitantes do site (Google Analytics)
Período: 30-90 dias
Nome: "Visitantes Site - 30-90 dias"
```

#### 2.3 Criativos (Banners)
- **Tamanhos:** 300x250, 728x90, 320x50 (mobile)
- **Texto:** "Volte ao EcoReport - 30 Dias Grátis"
- **Imagem:** Logo + CTA claro

---

## ✅ CHECKLIST PRÉ-LANÇAMENTO

### Facebook Ads
- [ ] Conta criada e verificada
- [ ] Facebook Pixel instalado e testado
- [ ] Conversão configurada (Lead/Signup)
- [ ] Audiências criadas (Cold, Warm, Hot)
- [ ] Criativos prontos (3-5 por campanha)
- [ ] Orçamento definido e configurado
- [ ] UTM parameters configurados

### Google Ads
- [ ] Conta criada e verificada
- [ ] Google Analytics 4 conectado
- [ ] Conversão configurada (Signup)
- [ ] Palavras-chave pesquisadas e organizadas
- [ ] Anúncios criados (3 por grupo)
- [ ] Extensões configuradas
- [ ] Orçamento definido

### Geral
- [ ] Landing page otimizada
- [ ] Tracking funcionando (testado)
- [ ] Relatórios configurados
- [ ] Alerts de CPA configurados

---

## 📊 CONFIGURAÇÕES DE OTIMIZAÇÃO

### Facebook Ads - Estratégia de Lance
- **Cold:** Custo mínimo por clique (inicial)
- **Warm:** Otimizar para conversões (após 50+ conversões)
- **Hot:** Maximizar conversões (após 100+ conversões)

### Google Ads - Estratégia de Lance
- **Inicial:** Custo por clique manual (CPC)
- **Após 100 conversões:** Custo por aquisição alvo (CPA)
- **Após estabilização:** Maximizar conversões

---

## 🎯 RESULTADOS ESPERADOS

### Primeira Semana
- **Facebook:** 500-1000 impressões, CTR 1-2%
- **Google:** 50-100 cliques, CTR 2-4%
- **Conversões:** 2-5 signups
- **CPA:** R$ 400-800 (aceitável inicial)

### Primeiro Mês
- **Facebook:** 20.000+ impressões, CTR > 1.5%
- **Google:** 500+ cliques, CTR > 2%
- **Conversões:** 10-20 signups
- **CPA:** R$ 250-500
- **ROAS:** 1.5-2.5x

---

**Guia criado por:** TRAFFIC MASTER OMEGA  
**Última atualização:** ${new Date().toISOString()}  
**Status:** PRODUCTION-READY 🚀

