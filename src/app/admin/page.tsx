'use client';

import { useEffect, useState } from 'react';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';

export default function AdminPage() {
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/signups')
      .then(res => res.json())
      .then(data => {
        setMessage(data.message || data.note || 'Carregando...');
        setLoading(false);
      })
      .catch(err => {
        setMessage('Erro ao carregar dados');
        setLoading(false);
      });
  }, []);

  return (
    <>
      <Header />
      <main className="min-h-screen bg-gradient-to-b from-slate-50 to-white py-20">
        <div className="container mx-auto px-4 max-w-6xl">
          <div className="bg-white rounded-lg shadow-lg p-8">
            <h1 className="text-3xl font-bold text-slate-900 mb-6">
              📊 Área Administrativa - Cadastros
            </h1>

            {loading ? (
              <p className="text-slate-600">Carregando...</p>
            ) : (
              <div className="space-y-4">
                <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                  <p className="text-blue-800 mb-2">
                    <strong>💡 Como ver os cadastros:</strong>
                  </p>
                  <ul className="list-disc list-inside text-blue-700 space-y-1 ml-4">
                    <li>
                      <strong>No terminal:</strong> Veja os logs em tempo real onde o servidor está rodando
                    </li>
                    <li>
                      <strong>No Google Sheets:</strong> Abra a planilha no Google Drive que você criou
                    </li>
                  </ul>
                </div>

                <div className="bg-emerald-50 border border-emerald-200 rounded-lg p-4">
                  <p className="text-emerald-800">
                    <strong>✅ Os cadastros estão funcionando!</strong>
                  </p>
                  <p className="text-emerald-700 text-sm mt-2">
                    Sempre que alguém se cadastra, você pode ver no console do servidor.
                  </p>
                </div>

                <div className="mt-6 pt-6 border-t border-slate-200">
                  <h2 className="text-xl font-semibold text-slate-900 mb-3">
                    🔗 Links Úteis
                  </h2>
                  <div className="space-y-2">
                    <a
                      href="https://drive.google.com/drive/my-drive"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="block text-blue-600 hover:text-blue-800 underline"
                    >
                      📁 Abrir Google Drive (para ver a planilha)
                    </a>
                    <a
                      href="https://script.google.com/home"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="block text-blue-600 hover:text-blue-800 underline"
                    >
                      📝 Apps Script (configurar planilha)
                    </a>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}

