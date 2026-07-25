// Service Worker mínimo — habilita o "Adicionar à tela inicial" na
// maioria dos navegadores (principalmente Android/Chrome). Não faz
// cache agressivo de propósito, pra sempre carregar a versão mais
// nova do app (evita alguém ficar "preso" numa versão antiga).

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  self.clients.claim();
});

// Handler de fetch "passivo": só repassa a requisição direto pra rede.
// A presença desse listener é o que muitos navegadores exigem pra
// considerar o site instalável como PWA.
self.addEventListener('fetch', (event) => {
  event.respondWith(fetch(event.request));
});
