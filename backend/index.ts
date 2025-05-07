import { createClient } from '@supabase/supabase-js';
import { Elysia, t } from 'elysia';

const supabaseUrl = process.env.SUPABASE_URL!;
const service_role = process.env.SERVICEROLEKEY!;
 // Ensure this is the Service Role Key

// Initialize Supabase client with Service Role Key
const supabase = createClient(supabaseUrl, service_role);

const app = new Elysia();

app.post('/create-user', async ({ body }) => {
    const { email, password, name, roles } = body;
  
    try {
      console.log('Creating user with:', { email, name, roles });
      const { data, error } = await supabase.auth.admin.createUser({
        email,
        password,
        user_metadata: {
          name,
          roles,
        },
      });
  
      if (error) {
        console.error('Error creating user:', error);
        return { success: false, error: error.message, details: error };
      }
  
      // Send confirmation email
      const { error: resendError } = await supabase.auth.resend({
        type: 'signup',
        email,
      });
  
      if (resendError) {
        console.error('Error sending confirmation email:', resendError);
        return { success: false, error: 'User created but failed to send confirmation email', details: resendError };
      }
  
      console.log('User created and confirmation email sent:', data);
      return { success: true, user: data, message: 'Confirmation email sent to user' };
    } catch (err) {
      console.error('Unexpected error:', err);
      return { success: false, error: 'Internal server error', details: err };
    }
  }, {
    body: t.Object({
      email: t.String(),
      password: t.String(),
      name: t.String(),
      roles: t.Array(t.String()),
    }),
  });
// LOGIN 
  app.post('/login', async ({ body }) => {
    const { email, password } = body;

    try {
   console.log('********************')
    console.log(email)
    console.log(password)
      
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });


  
      if (error) {
        if (error.message === 'Email not confirmed') {
          return { success: false, error: 'Please confirm your email before logging in' };
        }
        console.error('Error logging in:', error);
        return { success: false, error: error.message, details: error };
      }
  
      console.log('User logged in:', data);
      return { success: true, user: data.user, session: data.session };
    } catch (err) {
      console.error('Unexpected error:', err);
      return { success: false, error: 'Internal server error', details: err };
    }
  }, {
    body: t.Object({
      email: t.String(),
      password: t.String(),
    }),
  });

app.listen(3000);
console.log('✅ Elysia server is running on http://localhost:3000');