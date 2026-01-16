# 🚀 EcoReport - Plataforma de Gestão Fiscal e Financeira

Site institucional da plataforma **EcoReport**, uma solução completa de gestão fiscal, financeira e pedidos. Sistema moderno construído com Next.js 16, React 19 e TypeScript, com integração ao Google Sheets para captura de leads.

## ✨ Características

- 🎨 **Design Moderno e Responsivo** - Interface elegante com Tailwind CSS
- 📱 **Totalmente Responsivo** - Funciona perfeitamente em desktop, tablet e mobile
- 📊 **Integração com Google Sheets** - Cadastros salvos automaticamente no Google Sheets
- ⚡ **Performance Otimizada** - Construído com Next.js 16 e React 19
- 🔒 **Validação de Dados** - Validação robusta de formulários no cliente e servidor
- 📝 **SEO Otimizado** - Meta tags e estrutura otimizada para mecanismos de busca

## 🛠️ Tecnologias

- **Framework**: Next.js 16.1.2
- **React**: 19.2.3
- **TypeScript**: ^5
- **Estilização**: Tailwind CSS 4
- **Build Tool**: Turbopack
- **Linting**: ESLint com Next.js config

## 📋 Pré-requisitos

- Node.js 18+ (recomendado: Node.js 20+)
- npm ou yarn
- Conta Google (para configurar Google Sheets)

## 🚀 Instalação

1. **Clone o repositório**
```bash
git clone https://github.com/fabianosf/ecoreport-site.git
cd ecoreport-site
```

2. **Instale as dependências**
```bash
npm install
```

3. **Configure as variáveis de ambiente**
```bash
cp .env.example .env.local
```

Edite o arquivo `.env.local` e adicione:
```env
GOOGLE_WEBHOOK_URL=https://script.google.com/macros/s/SEU_ID_AQUI/exec
```

4. **Execute o servidor de desenvolvimento**
```bash
npm run dev
```

Acesse [http://localhost:3000](http://localhost:3000) no seu navegador.

## 📊 Configuração do Google Sheets

Para que os cadastros sejam salvos automaticamente no Google Sheets:

### 1. Criar Planilha no Google Sheets

1. Acesse [Google Sheets](https://sheets.google.com) e crie uma nova planilha
2. Nomeie como "EcoReport Signups"
3. Adicione os cabeçalhos na primeira linha:
   - Coluna A: `Timestamp`
   - Coluna B: `Nome`
   - Coluna C: `Email`
   - Coluna D: `Empresa`

### 2. Configurar Google Apps Script

1. Acesse [Google Apps Script](https://script.google.com)
2. Crie um novo projeto
3. Cole o código do arquivo `APP_SCRIPT_CODE.js`
4. **IMPORTANTE**: Substitua `'COLE_O_ID_DA_PLANILHA_AQUI'` pelo ID real da sua planilha
   - O ID da planilha está na URL: `https://docs.google.com/spreadsheets/d/[ID_AQUI]/edit`
5. Salve o código (Ctrl+S)
6. Clique em **Implantar** → **Novo Implantação**
7. Configure:
   - Tipo: **Aplicativo da Web**
   - Execute como: **Você**
   - Quem tem acesso: **Qualquer pessoa**
8. Copie a URL da implantação
9. Cole a URL no arquivo `.env.local` como `GOOGLE_WEBHOOK_URL`

### 3. Script de Setup Automático (Opcional)

Você também pode usar o script de setup automatizado:
```bash
chmod +x setup.sh
./setup.sh
```

## 📁 Estrutura do Projeto

```
ecoreport-site/
├── src/
│   ├── app/
│   │   ├── admin/          # Página administrativa
│   │   ├── api/
│   │   │   ├── signup/     # API de cadastro
│   │   │   └── signups/    # API de listagem
│   │   ├── layout.tsx      # Layout principal
│   │   └── page.tsx        # Página inicial
│   ├── components/
│   │   ├── common/         # Componentes reutilizáveis
│   │   ├── layout/         # Header e Footer
│   │   └── sections/       # Seções da página inicial
│   ├── lib/                # Utilitários e constantes
│   ├── styles/             # Estilos globais e animações
│   └── types/              # Definições TypeScript
├── public/                 # Arquivos estáticos
├── APP_SCRIPT_CODE.js      # Código do Google Apps Script
├── setup.sh                # Script de setup automatizado
└── package.json
```

## 🎯 Scripts Disponíveis

```bash
# Desenvolvimento
npm run dev          # Inicia servidor de desenvolvimento

# Produção
npm run build        # Cria build de produção
npm run start        # Inicia servidor de produção

# Qualidade de Código
npm run lint         # Executa ESLint
```

## 🔌 API Endpoints

### POST `/api/signup`
Endpoint para cadastro de novos usuários.

**Request Body:**
```json
{
  "name": "Nome Completo",
  "email": "email@exemplo.com",
  "company": "Nome da Empresa"
}
```

**Response:**
```json
{
  "message": "Cadastro realizado com sucesso!",
  "success": true
}
```

## 🌐 Páginas

- `/` - Página inicial com landing page
- `/admin` - Área administrativa (informações sobre visualização de cadastros)

## 🎨 Componentes Principais

- **HeroSection** - Seção hero com CTA principal
- **FeaturesSection** - Lista de funcionalidades
- **BenefitsSection** - Benefícios da plataforma
- **PricingSection** - Planos e preços
- **FAQSection** - Perguntas frequentes
- **SignupModal** - Modal de cadastro

## 📝 Variáveis de Ambiente

Crie um arquivo `.env.local` na raiz do projeto:

```env
GOOGLE_WEBHOOK_URL=https://script.google.com/macros/s/SEU_ID/exec
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para:

1. Fazer um Fork do projeto
2. Criar uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abrir um Pull Request

## 📄 Licença

Este projeto é privado e pertence a EcoReport.

## 👤 Autor

**Fabiano Sousa de Freitas**

- GitHub: [@fabianosf](https://github.com/fabianosf)
- Email: fabiano.freitas@gmail.com

## 🙏 Agradecimentos

- Next.js Team
- Vercel
- Google Apps Script

---

⭐ Se este projeto foi útil para você, considere dar uma estrela no repositório!
