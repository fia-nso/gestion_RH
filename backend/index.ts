import { Elysia } from 'elysia';
import { supabase } from './src/services/supabase';

const app = new Elysia()
  .get('/', () => 'Bienvenue sur le backend de l\'application RH !')
  .get('/test-supabase', async () => {
    const { data, error } = await supabase.from('test').select('*');
    return { data, error };
  })
  .listen(3000);

console.log(`Serveur Elysia démarré sur http://localhost:${app.server?.port}`);