// import { createClient } from '@supabase/supabase-js';
// import { Elysia, t } from 'elysia';

// const supabaseUrl = process.env.SUPABASE_URL!;
// const service_role = process.env.SERVICEROLEKEY!;
//  // Ensure this is the Service Role Key

// // Initialize Supabase client with Service Role Key
// const supabase = createClient(supabaseUrl, service_role);

// const app = new Elysia();

// app.post('/create-user', async ({ body }) => {
//     const { email, password, name, roles } = body;

//     try {
//       console.log('Creating user with:', { email, name, roles });
//       const { data, error } = await supabase.auth.admin.createUser({
//         email,
//         password,
//         user_metadata: {
//           name,
//           roles,
//         },
//       });

//       if (error) {
//         console.error('Error creating user:', error);
//         return { success: false, error: error.message, details: error };
//       }

//       // Send confirmation email
//       const { error: resendError } = await supabase.auth.resend({
//         type: 'signup',
//         email,
//       });

//       if (resendError) {
//         console.error('Error sending confirmation email:', resendError);
//         return { success: false, error: 'User created but failed to send confirmation email', details: resendError };
//       }

//       console.log('User created and confirmation email sent:', data);
//       return { success: true, user: data, message: 'Confirmation email sent to user' };
//     } catch (err) {
//       console.error('Unexpected error:', err);
//       return { success: false, error: 'Internal server error', details: err };
//     }
//   }, {
//     body: t.Object({
//       email: t.String(),
//       password: t.String(),
//       name: t.String(),
//       roles: t.Array(t.String()),
//     }),
//   });
// // LOGIN
//   app.post('/login', async ({ body }) => {
//     const { email, password } = body;

//     try {
//    console.log('********************')
//     console.log(email)
//     console.log(password)

//       const { data, error } = await supabase.auth.signInWithPassword({
//         email,
//         password,
//       });

//       if (error) {
//         if (error.message === 'Email not confirmed') {
//           return { success: false, error: 'Please confirm your email before logging in' };
//         }
//         console.error('Error logging in:', error);
//         return { success: false, error: error.message, details: error };
//       }

//       console.log('User logged in:', data);
//       return { success: true, user: data.user, session: data.session };
//     } catch (err) {
//       console.error('Unexpected error:', err);
//       return { success: false, error: 'Internal server error', details: err };
//     }
//   }, {
//     body: t.Object({
//       email: t.String(),
//       password: t.String(),
//     }),
//   });

// app.listen(3000);
// console.log('✅ Elysia server is running on http://localhost:3000');

import { Elysia, t } from "elysia";
import { createClient, type User } from "@supabase/supabase-js";
import { cors } from "@elysiajs/cors";
// import { jwt } from '@elysiajs/jwt';
// import { staticPlugin } from '@elysiajs/static';

const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseRoleKey = process.env.SERVICEROLEKEY!;
// const jwtSecret = process.env.JWT_SECRET!;

// Supabase client
const supabase = createClient(supabaseUrl, supabaseRoleKey);

// Define the Supabase user type for context
interface SupabaseUser {
  id: string;
  user_metadata?: {
    name?: string;
    contact?: string;
    details?: string;
    photo?: string;
    status?: string;
    start_date?: string;
    roles?: string[];
    [key: string]: any;
  };
  [key: string]: any;
}

// Extend Elysia's context to include user
// interface CustomContext {
//   request: {
//     user: SupabaseUser;
//   };
// }

// Initialize app with custom context
const app = new Elysia();
// allow cors
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
    credentials: true,
  })
);

//  Login
app
  .post(
    "/login",
    async ({ body }) => {
      const { email, password } = body;

      try {
        const { data, error } = await supabase.auth.signInWithPassword({
          email,
          password,
        });

        if (error) {
          if (error.message === "Email not confirmed") {
            return {
              success: false,
              error: "Please confirm your email before logging in",
            };
          }
          console.error("Error logging in:", error);
          return { success: false, error: error.message, details: error };
        }

        console.log("User logged in:", data);
        return { success: true, user: data.user, session: data.session };
      } catch (err) {
        console.error("Unexpected error:", err);
        return { success: false, error: "Internal server error", details: err };
      }
    },
    {
      body: t.Object({
        email: t.String(),
        password: t.String(),
      }),
    }
  )
  // .get("/status", () => {
  //   return { ok: "ok" };
  // })

  // Create user
  .post(
    "/user",
    async ({ body, headers, set }) => {
      const {
        email,
        password,
        name,
        contact,
        photo,
        details,
        start_date,
        status,
        roles,
      } = body;

      // Get current user info from Authorization header
      const token = headers.authorization?.replace("Bearer ", "");
      const { data: userInfo, error: userInfoError } =
        await supabase.auth.getUser(token);

      if (userInfoError || !userInfo?.user) {
        set.status = 401;
        return { success: false, error: "Unauthorized" };
      }

      const currentUser = userInfo.user;
      const currentRoles = currentUser.user_metadata?.roles || [];
      const isAdmin = currentRoles.includes("admin");

      if (!isAdmin) {
        set.status = 403;
        return {
          success: false,
          error: "Only admins can create users with the role",
        };
      }

      try {
        // Create user
        const { data: createdUser, error } =
          await supabase.auth.admin.createUser({
            email,
            password,
            user_metadata: {
              name,
              contact,
              details,
              start_date,
              status,
              roles,
            },
            email_confirm: true,
          });

        if (error) {
          set.status = 400;
          return { success: false, error: error.message, details: error };
        }

        const userId = createdUser.user?.id;
        if (!userId) {
          set.status = 500;
          return { success: false, error: "User created but no ID returned" };
        }

        // Handle photo upload if provided
        let photoUrl = null;
        if (photo) {
          const photoPath = `employer/${userId}/${Date.now()}.jpg`;
          const { error: uploadError } = await supabase.storage
            .from("employees")
            .upload(photoPath, photo, {
              contentType: photo.type,
              upsert: true,
            });

          if (uploadError) {
            set.status = 500;
            return {
              success: false,
              error: "Failed to upload photo",
              details: uploadError.message,
            };
          }

          // Get the public URL of the uploaded photo
          photoUrl = supabase.storage.from("employees").getPublicUrl(photoPath)
            .data.publicUrl;

          // Update user_metadata with photoUrl
          const { error: updateError } =
            await supabase.auth.admin.updateUserById(userId, {
              user_metadata: {
                name,
                contact,
                details,
                start_date,
                status,
                roles,
                photo: photoUrl,
              },
            });

          if (updateError) {
            set.status = 500;
            return {
              success: false,
              error: "Failed to update user metadata with photo URL",
              details: updateError.message,
            };
          }
        }

        // Insert into role-specific table
        const role = roles[0]; // Assuming a single role
        let insertResult;

        switch (role) {
          case "admin":
            insertResult = await supabase.from("admin").insert({
              id: userId,
              // name,
            });
            break;

          case "employer":
            insertResult = await supabase.from("employer").insert({
              id: userId,
              contact,
              details,
              photo: photoUrl,
              start_date,
            });
            break;

          case "assistant":
            insertResult = await supabase.from("assistant").insert({
              id: userId,
            });
            break;

          default:
            set.status = 400;
            return {
              success: false,
              error: `Unknown role: ${role}`,
            };
        }

        if (insertResult.error) {
          set.status = 500;
          return {
            success: false,
            error: `User created, but failed to insert into ${role} table`,
            details: insertResult.error.message,
          };
        }

        return {
          success: true,
          user: {
            id: userId,
            email,
            user_metadata: {
              name,
              contact,
              details,
              photo: photoUrl,
              start_date,
              status,
              roles,
            },
          },
          message: `User created, confirmed, and inserted into ${role} table`,
        };
      } catch (err) {
        console.error("Error creating user:", err);
        set.status = 500;
        return {
          success: false,
          error: "Internal server error",
          details: err instanceof Error ? err.message : JSON.stringify(err),
        };
      }
    },
    {
      body: t.Object({
        email: t.String(),
        password: t.String(),
        name: t.String(),
        status: t.String(),
        contact: t.Nullable(t.String()),
        details: t.Nullable(t.String()),
        start_date: t.String(),
        photo: t.Optional(t.File()),
        roles: t.Array(t.String()),
      }),
    }
  );

// // Create employer
// .post('/', async ({ body, set, request }) => {
//   const user = (request as any).user as SupabaseUser;
//   if (!user.user_metadata?.roles?.includes('admin')) {
//     set.status = 403;
//     return { success: false, error: 'Only admins can create employers' };
//   }

//   const { name, email, contact, details, photo } = body;
//   let photoUrl = null;

//   if (photo) {
//     const { data, error } = await supabase.storage
//       .from('employees')
//       .upload(`${Date.now()}_${name}.jpg`, photo, {
//         contentType: photo.type,
//       });

//     if (error) {
//       set.status = 500;
//       return { success: false, error: 'Failed to upload photo' };
//     }

//     const { data: publicUrl } = supabase.storage
//       .from('employees')
//       .getPublicUrl(data.path);
//     photoUrl = publicUrl.publicUrl;
//   }

//   const { data, error } = await supabase.from('users').insert([
//     { name, email, contact,details, photo_url: photoUrl },
//   ]).select().single();

//   if (error) {
//     set.status = 500;
//     return { success: false, error: error.message };
//   }
//   return { success: true, employer: data };
// }, {
//   body: t.Object({
//     name: t.String(),
//     email: t.String({ format: 'email' }),
//     contact: t.String(),
//     details: t.String(),
//     photo: t.Optional(t.File()),
//   }),
// })

// // Update employer
// .patch('/:id', async ({ body, params, set, request }) => {
//   const user = (request as any).user as SupabaseUser;
//   if (!user.user_metadata?.roles?.includes('admin')) {
//     set.status = 403;
//     return { success: false, error: 'Only admins can update employers' };
//   }

//   const { name, email, phone_number, photo, photo_url } = body;
//   let updatedPhotoUrl = photo_url;

//   if (photo) {
//     const { data, error } = await supabase.storage
//       .from('employee-photos')
//       .upload(`${Date.now()}_${name}.jpg`, photo, {
//         contentType: photo.type,
//       });

//     if (error) {
//       set.status = 500;
//       return { success: false, error: 'Failed to upload photo' };
//     }

//     const { data: publicUrl } = supabase.storage
//       .from('employee-photos')
//       .getPublicUrl(data.path);
//     updatedPhotoUrl = publicUrl.publicUrl;
//   }

//   const { data, error } = await supabase
//     .from('users')
//     .update({ name, email, phone_number, photo_url: updatedPhotoUrl })
//     .eq('id', params.id)
//     .select()
//     .single();

//   if (error) {
//     set.status = 500;
//     return { success: false, error: error.message };
//   }

//   return { success: true, employer: data };
// }, {
//   body: t.Object({
//     name: t.String(),
//     email: t.String({ format: 'email' }),
//     phone_number: t.String(),
//     photo: t.Optional(t.File()),
//     photo_url: t.Optional(t.String()),
//   }),
// })

// .patch(
//   "/:id",
//   async ({ body, params, set, request, headers }) => {
//     const user = (request as any).user as SupabaseUser;
//     const token = headers.authorization?.replace("Bearer ", "");

//     // Supabase client authentifié avec token utilisateur
//     const supabaseClient = createClient(supabaseUrl, token!, {
//       global: { headers: { Authorization: `Bearer ${token}` } },
//     });

//     if (!user.user_metadata?.roles?.includes("admin")) {
//       set.status = 403;
//       return { success: false, error: "Only admins can update users" };
//     }

//     const { name, contact, details, photo } = body;

//     try {
//       // 1. Vérifier si l'utilisateur existe
//       const { data: existingUser, error: fetchError } = await supabaseClient
//         .from("users")
//         .select("id")
//         .eq("id", params.id)
//         .single();

//       if (fetchError || !existingUser) {
//         set.status = 404;
//         return { success: false, error: "User not found in public.users" };
//       }

//       // 2. Mise à jour table public.users
//       const updateData: any = {};
//       if (name !== undefined) updateData.name = name;
//       if (contact !== undefined) updateData.contact = contact;
//       if (details !== undefined) updateData.details = details;
//       if (photo !== undefined) updateData.photo = photo;

//       const { data: updatedUser, error: updateError } = await supabaseClient
//         .from("users")
//         .update(updateData)
//         .eq("id", params.id)
//         .select()
//         .single();

//       if (updateError) {
//         set.status = 500;
//         return {
//           success: false,
//           error: `Failed to update public.users: ${updateError.message}`,
//         };
//       }

//       // 3. Mise à jour user_metadata **seulement si l'admin modifie son propre compte**
//       if (user.id === params.id) {
//         const { error: metaError } = await supabaseClient.auth.updateUser({
//           data: updateData,
//         });

//         if (metaError) {
//           set.status = 500;
//           return {
//             success: false,
//             error: `Failed to update own metadata: ${metaError.message}`,
//           };
//         }
//       }

//       return {
//         success: true,
//         user: updatedUser,
//         message:
//           user.id === params.id
//             ? "User and metadata updated"
//             : "User updated (metadata skipped: can only update own metadata)",
//       };
//     } catch (err) {
//       console.error("PATCH /:id error", err);
//       set.status = 500;
//       return {
//         success: false,
//         error: "Internal server error",
//         details: err instanceof Error ? err.message : JSON.stringify(err),
//       };
//     }
//   },
//   {
//     body: t.Object({
//       name: t.Optional(t.String()),
//       contact: t.Optional(t.String()),
//       details: t.Optional(t.String()),
//       photo: t.Optional(t.String()),
//     }),
//   }
// )

// Employee routes
app.group("/employers", (app) =>
  app
    // Middleware to check authentication and roles
    .onBeforeHandle(async ({ headers, set, request }) => {
      const token = headers.authorization?.replace("Bearer ", "");
      if (!token) {
        set.status = 401;
        return { success: false, error: "Unauthorized: No token provided" };
      }
      const {
        data: { user },
        error,
      } = await supabase.auth.getUser(token);
      if (error || !user) {
        set.status = 401;
        return { success: false, error: "Invalid token" };
      }

      // Attach the user to the request object
      (request as any).user = user as SupabaseUser;
    })

    // Delete employer
    .delete("/:id", async ({ params, set, request }) => {
      const user = (request as any).user as SupabaseUser;
      if (!user.user_metadata?.roles?.includes("admin")) {
        set.status = 403;
        return { success: false, error: "Only admins can delete users" };
      }

      // Fetch user to determine role
      const { data: authUser, error: authError } =
        await supabase.auth.admin.getUserById(params.id);
      if (authError || !authUser?.user) {
        set.status = 404;
        return { success: false, error: "User not found" };
      }

      const role = authUser.user.user_metadata?.roles?.[0];
      if (!role) {
        set.status = 400;
        return { success: false, error: "User has no role" };
      }

      // Delete from role-specific table
      const { error: tableError } = await supabase
        .from(role)
        .delete()
        .eq("id", params.id);

      if (tableError) {
        set.status = 500;
        return {
          success: false,
          error: `Failed to delete ${role}: ${tableError.message}`,
        };
      }

      // Delete from auth.users
      const { error: userError } = await supabase.auth.admin.deleteUser(
        params.id
      );
      if (userError) {
        set.status = 500;
        return {
          success: false,
          error: `Failed to delete user: ${userError.message}`,
        };
      }

      return {
        success: true,
        message: `${role} and associated user deleted successfully`,
      };
    })

    .patch(
      "/:id",
      async ({ body, params, set }) => {
        const { name } = body;

        try {
          const { error } = await supabase
            .from("users")
            .update({ name: name })
            .eq("id", params.id);

          if (error) {
            set.status = 404;
            return { success: false, error: "User not found in public.users" };
          }
        } catch (err) {
          console.error("Unexpected error:", err);
          return {
            success: false,
            error: "Internal server error",
            details: err,
          };
        }
      },
      {
        body: t.Object({
          name: t.String(),
        }),
      }
    )
);




app.group("/projects", (app) =>
  app
    // Middleware to check authentication and roles
    .onBeforeHandle(async ({ headers, set, request }) => {
      const token = headers.authorization?.replace("Bearer ", "");
      if (!token) {
        set.status = 401;
        return { success: false, error: "Unauthorized: No token provided" };
      }

      const {
        data: { user },
        error,
      } = await supabase.auth.getUser(token);

      if (error || !user) {
        set.status = 401;
        return { success: false, error: "Invalid token" };
      }

      // Attach the user to the request object
      (request as any).user = user as SupabaseUser;
    })

    // GET /projects - Get all projects
    .get("/", async ({ set }) => {
      try {
        const { data, error } = await supabase
          .from("projects")
          .select(`
            *,
            employer:employer_id(id, contact, details),
            creator:created_by(id, name, email),
            assignee:assigned_to(id, name, email),
            project_employees(
              id,
              role,
              employee:employee_id(id, contact, details)
            )
          `)
          .order("created_at", { ascending: false });

        if (error) {
          set.status = 400;
          return { success: false, error: error.message };
        }

        return { success: true, data };
      } catch (err) {
        console.error("Unexpected error:", err);
        set.status = 500;
        return {
          success: false,
          error: "Internal server error",
          details: err,
        };
      }
    })

    // GET /projects/:id - Get specific project
    .get("/:id", async ({ params, set }) => {
      try {
        const { data, error } = await supabase
          .from("projects")
          .select(`
            *,
            employer:employer_id(id, contact, details, photo, start_date),
            creator:created_by(id, name, email, status),
            assignee:assigned_to(id, name, email, status),
            project_employees(
              id,
              role,
              assigned_at,
              employee:employee_id(id, contact, details, photo, start_date)
            ),
            project_absences(
              id,
              impact_level,
              absence:absence_id(id, employee_id, absence_type, date, duration_minutes, reason, status)
            )
          `)
          .eq("id", params.id)
          .single();

        if (error) {
          set.status = 400;
          return { success: false, error: error.message };
        }

        if (!data) {
          set.status = 404;
          return { success: false, error: "Project not found" };
        }

        return { success: true, data };
      } catch (err) {
        console.error("Unexpected error:", err);
        set.status = 500;
        return {
          success: false,
          error: "Internal server error",
          details: err,
        };
      }
    })

    .post("/", async ({ body, set, request }) => {
      const user = (request as any).user as SupabaseUser;

      // Check if user is admin
      if (!user.user_metadata?.roles?.includes("admin")) {
        set.status = 403;
        return { success: false, error: "Only admins can create projects" };
      }

      const {
        name,
        description,
        startDate,
        endDate,
        size,
        scope,
        status,
      } = body;

      try {
        // Validation des données requises
        if (!name || !description) {
          set.status = 400;
          return {
            success: false,
            error: "Name and description are required"
          };
        }

        // Insertion du projet
        const { data: projectData, error: projectError } = await supabase
          .from("projects")
          .insert([
            {
              name,
              description,
              start_date: startDate,
              end_date: endDate,
              size,
              scope,
              status: status || 'planning',
              created_by: user.id,
            },
          ])
          .select()
          .single();

        if (projectError) {
          set.status = 400;
          return { success: false, error: projectError.message };
        }

        set.status = 201;
        return {
          success: true,
          data: projectData,
          message: "Project created successfully"
        };
      } catch (err) {
        console.error("Unexpected error:", err);
        set.status = 500;
        return {
          success: false,
          error: "Internal server error",
          details: err,
        };
      }
    }, {
      body: t.Object({
        name: t.String(),
        description: t.String(),
        startDate: t.Optional(t.String()),
        endDate: t.Optional(t.String()),
        size: t.Optional(t.String()),
        scope: t.Optional(t.String()),
        status: t.Optional(t.String()),
      }),
    })

    // PUT /projects/:id - Update project
    .put("/:id", async ({ body, params, set, request }) => {
      const user = (request as any).user as SupabaseUser;

      // Check if user is admin
      if (!user.user_metadata?.roles?.includes("admin")) {
        set.status = 403;
        return { success: false, error: "Only admins can update projects" };
      }

      const {
        name,
        description,
        startDate,
        endDate,
        size,
        scope,
        status,
        employerId,
        assignedTo,
        employeeIds = []
      } = body;

      try {
        // Vérifier que le projet existe
        const { data: existingProject, error: checkError } = await supabase
          .from("projects")
          .select("id, name")
          .eq("id", params.id)
          .single();

        if (checkError || !existingProject) {
          set.status = 404;
          return { success: false, error: "Project not found" };
        }

        // Mise à jour du projet
        const { data, error } = await supabase
          .from("projects")
          .update({
            name,
            description,
            start_date: startDate,
            end_date: endDate,
            size,
            scope,
            status,
            employer_id: employerId,
            assigned_to: assignedTo,
          })
          .eq("id", params.id)
          .select()
          .single();

        if (error) {
          set.status = 400;
          return { success: false, error: error.message };
        }

        // Mise à jour des assignations d'employés
        if (employeeIds.length >= 0) {
          // Supprimer les anciennes assignations
          await supabase
            .from("project_employees")
            .delete()
            .eq("project_id", params.id);

          // Ajouter les nouvelles assignations
          if (employeeIds.length > 0) {
            const employeeAssignments = employeeIds.map((employeeId: any) => ({
              project_id: params.id,
              employee_id: employeeId
            }));

            await supabase
              .from("project_employees")
              .insert(employeeAssignments);
          }
        }

        return {
          success: true,
          data,
          message: "Project updated successfully"
        };
      } catch (err) {
        console.error("Unexpected error:", err);
        set.status = 500;
        return {
          success: false,
          error: "Internal server error",
          details: err,
        };
      }
    }, {
      body: t.Object({
        name: t.Optional(t.String()),
        description: t.Optional(t.String()),
        startDate: t.Optional(t.String()),
        endDate: t.Optional(t.String()),
        size: t.Optional(t.String()),
        scope: t.Optional(t.String()),
        status: t.Optional(t.String()),
        employerId: t.Optional(t.String()),
        assignedTo: t.Optional(t.String()),
        employeeIds: t.Optional(t.Array(t.String())),
      }),
    })

    // DELETE /projects/:id - Delete project
    .delete("/:id", async ({ params, set, request }) => {
      const user = (request as any).user as SupabaseUser;

      // Check if user is admin
      if (!user.user_metadata?.roles?.includes("admin")) {
        set.status = 403;
        return { success: false, error: "Only admins can delete projects" };
      }

      try {
        const { data, error } = await supabase
          .from("projects")
          .delete()
          .eq("id", params.id)
          .select()
          .single();

        if (error) {
          set.status = 400;
          return { success: false, error: error.message };
        }

        if (!data) {
          set.status = 404;
          return { success: false, error: "Project not found" };
        }

        return {
          success: true,
          message: "Project deleted successfully",
          data
        };
      } catch (err) {
        console.error("Unexpected error:", err);
        set.status = 500;
        return {
          success: false,
          error: "Internal server error",
          details: err,
        };
      }
    })

    // PATCH /projects/:id - Partial update (like employers)
    .patch("/:id", async ({ body, params, set }) => {
      const { name } = body;

      try {
        const { error } = await supabase
          .from("projects")
          .update({ name: name })
          .eq("id", params.id);

        if (error) {
          set.status = 404;
          return { success: false, error: "Project not found in projects table" };
        }

        return { success: true, message: "Project updated successfully" };
      } catch (err) {
        console.error("Unexpected error:", err);
        return {
          success: false,
          error: "Internal server error",
          details: err,
        };
      }
    }, {
      body: t.Object({
        name: t.String(),
      }),
    })
);


app.listen(3000, () => {
  console.log("✅ Server running on http://localhost:3000");
});
