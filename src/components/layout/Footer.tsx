'use client';

import Link from 'next/link';
import Container from '@/components/common/Container';

export default function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="bg-slate-900 text-slate-300 py-16">
      <Container>
        {/* Main Footer Content */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-12 mb-12">
          {/* Brand Section */}
          <div>
            <div className="flex items-center gap-2 mb-4">
              <div className="w-8 h-8 bg-gradient-to-br from-emerald-400 to-emerald-600 rounded-lg flex items-center justify-center text-lg font-bold text-white">
                🌱
              </div>
              <span className="text-xl font-bold text-emerald-400">EcoReport</span>
            </div>
            <p className="text-sm text-slate-400 leading-relaxed">
              Plataforma completa de gestão fiscal, financeira e pedidos para impulsionar seu negócio.
            </p>
            <div className="flex gap-4 mt-6">
              <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M8.29 20v-7.21H5.93V9.25h2.36V7.75c0-2.33 1.43-3.61 3.51-3.61 1 0 1.86.07 2.11.11v2.44h-1.44c-1.14 0-1.36.54-1.36 1.33V9.25h2.71l-.35 3.54h-2.36V20H8.29Z" />
                </svg>
              </a>
              <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M23 3a10.9 10.9 0 01-3.14 1.53 4.48 4.48 0 00-7.86 3v1A10.66 10.66 0 013 4s-4 9 5 13a11.64 11.64 0 01-7 2s9 5 20 5a9.5 9.5 0 00-9-5.5c4.75 2.25 7-7 7-7" />
                </svg>
              </a>
              <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M16 8a6 6 0 016 6v7h-4v-7a2 2 0 00-2-2 2 2 0 00-2 2v7h-4v-7a6 6 0 016-6zM2 9h4v12H2z" />
                </svg>
              </a>
            </div>
          </div>

          {/* Produto */}
          <div>
            <h3 className="text-white font-semibold mb-6 text-lg">Produto</h3>
            <ul className="space-y-3 text-sm">
              <li>
                <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                  Funcionalidades
                </a>
              </li>
              <li>
                <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                  Planos e Preços
                </a>
              </li>
              <li>
                <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                  Segurança
                </a>
              </li>
              <li>
                <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                  Roadmap
                </a>
              </li>
              <li>
                <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                  API Docs
                </a>
              </li>
            </ul>
          </div>

          {/* Empresa */}
          <div>
            <h3 className="text-white font-semibold mb-6 text-lg">Empresa</h3>
            <ul className="space-y-3 text-sm">
              <li>
                <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                  Sobre Nós
                </a>
              </li>
              <li>
                <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                  Blog
                </a>
              </li>
              <li>
                <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                  Carreiras
                </a>
              </li>
              <li>
                <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                  Imprensa
                </a>
              </li>
              <li>
                <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                  Status
                </a>
              </li>
            </ul>
          </div>

          {/* Suporte */}
          <div>
            <h3 className="text-white font-semibold mb-6 text-lg">Suporte</h3>
            <ul className="space-y-3 text-sm">
              <li>
                <a href="mailto:contato@ecoreport.app" className="text-slate-400 hover:text-emerald-400 transition-colors">
                  📧 contato@ecoreport.app
                </a>
              </li>
              <li>
                <a href="mailto:suporte@ecoreport.app" className="text-slate-400 hover:text-emerald-400 transition-colors">
                  📞 suporte@ecoreport.app
                </a>
              </li>
              <li>
                <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                  Centro de Ajuda
                </a>
              </li>
              <li>
                <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                  FAQ
                </a>
              </li>
              <li>
                <a href="#" className="text-slate-400 hover:text-emerald-400 transition-colors">
                  Documentação
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Divider */}
        <div className="border-t border-slate-700 pt-8 mb-8">
          {/* Newsletter */}
          <div className="mb-8">
            <h4 className="text-white font-semibold mb-4">Fique Atualizado</h4>
            <p className="text-sm text-slate-400 mb-4">
              Receba novidades sobre novas funcionalidades e melhorias.
            </p>
            <div className="flex gap-2">
              <input
                type="email"
                placeholder="seu@email.com"
                className="flex-1 px-4 py-2 rounded-lg bg-slate-800 text-white text-sm border border-slate-700 focus:border-emerald-500 focus:outline-none"
              />
              <button className="px-6 py-2 bg-emerald-500 text-white rounded-lg font-medium hover:bg-emerald-600 transition-colors text-sm">
                Inscrever
              </button>
            </div>
          </div>
        </div>

        {/* Bottom Footer */}
        <div className="border-t border-slate-700 pt-8">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <div className="text-sm text-slate-400">
              <p>
                © {currentYear} <span className="text-emerald-400 font-semibold">EcoReport</span>. Todos os direitos reservados.
              </p>
              <p className="mt-2">
                Desenvolvido com ❤️ por <a href="#" className="text-emerald-400 hover:underline">Fabiano Freitas</a>
              </p>
            </div>

            {/* Legal Links */}
            <div className="flex flex-wrap gap-6 text-sm text-slate-400">
              <a href="#" className="hover:text-emerald-400 transition-colors">
                Privacidade
              </a>
              <a href="#" className="hover:text-emerald-400 transition-colors">
                Termos de Serviço
              </a>
              <a href="#" className="hover:text-emerald-400 transition-colors">
                Cookies
              </a>
              <a href="#" className="hover:text-emerald-400 transition-colors">
                LGPD
              </a>
            </div>
          </div>

          {/* Contact Info */}
          <div className="bg-slate-800 rounded-lg p-4 text-sm text-slate-400 border border-slate-700">
            <p>
              <strong className="text-white">Contato:</strong> +55 (21) 99407-8286 | 
              <strong className="text-white ml-4">CNPJ:</strong> 56.972.989/0001-50 | 
              <strong className="text-white ml-4">Endereço:</strong> Rio de Janeiro, RJ              
            </p>
          </div>
        </div>
      </Container>
    </footer>
  );
}
