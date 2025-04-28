import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://lourroesreukeofjjfox.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvdXJyb2VzcmV1a2VvZmpqZm94Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4NDM3NDYsImV4cCI6MjA2MTQxOTc0Nn0.fNhd8WJYAN3FLNcDVHCG8f7tVyMCSxsJuj5EkLK4ccw';
export const supabase = createClient(supabaseUrl, supabaseKey);