import { Elysia } from 'elysia';
import { supabase } from './src/services/supabase';

const app = new Elysia()

  // Route de base
  .get('/', () => 'Bienvenue sur le backend de l\'application RH !')

  // Route de test Supabase
  .get('/test-supabase', async () => {
    try {
      const { data, error } = await supabase.auth.getSession();
      if (error) return { error: error.message };
      return { message: "Connexion Supabase réussie", session: data };
    } catch (err) {
      return { error: err instanceof Error ? err.message : 'Erreur inconnue' };
    }
  })

  // Route de login
  .post('/login', async ({ body }) => {
    const { email, password } = body as { email: string; password: string };
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) return { error: error.message };
    return { data };
  })

  // Middleware: vérifie le token et le rôle
  .get('/admin-only', async ({ request }) => {
    const token = request.headers.get('Authorization')?.replace('Bearer ', '');
    if (!token) return new Response('Token manquant', { status: 401 });

    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) return new Response('Non autorisé', { status: 401 });

    const { data: profile, error: roleError } = await supabase
      .from('profiles')
      .select('role')
      .eq('user_id', user.id)
      .single();

    if (roleError || !profile) return new Response('Profil introuvable', { status: 403 });
    if (profile.role !== 'admin') return new Response('Accès interdit', { status: 403 });

    return new Response('Bienvenue Admin !');
  })

  .listen(3000);

console.log(`✅ Serveur Elysia lancé : http://localhost:${app.server?.port}`);
