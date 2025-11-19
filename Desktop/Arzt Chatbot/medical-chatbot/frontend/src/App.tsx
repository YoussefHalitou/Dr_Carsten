import { ChatWidget } from './components/ChatWidget';

const App = () => {
  return (
    <div className="min-h-screen bg-gray-100 p-6">
      <div className="mx-auto max-w-4xl rounded-3xl bg-white p-10 shadow-sm">
        <h1 className="text-3xl font-semibold text-slate-800">Willkommen in der Online-Rezeption</h1>
        <p className="mt-4 max-w-2xl text-slate-600">
          Unser digitaler Assistent hilft Ihnen bei allen Anliegen rund um Ihre Arztpraxis. Starten Sie den Chat über das
          Symbol unten rechts, um Termine zu vereinbaren oder zu ändern, Rezepte anzufordern, Krankmeldungen zu erhalten oder
          Fragen zu Befunden, Öffnungszeiten und Kontaktmöglichkeiten zu stellen.
        </p>
      </div>
      <ChatWidget />
    </div>
  );
};

export default App;
