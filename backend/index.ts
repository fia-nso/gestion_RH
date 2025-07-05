import { Elysia, t } from "elysia";
import { createClient } from "@supabase/supabase-js";
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

    // GET /employers - List only employers with pagination and filtering
    // .get("/", async ({ query, set, request }) => {
    //   const user = (request as any).user as SupabaseUser;
    //   const userRoles = user.user_metadata?.roles || [];

    //   // Only admins can view the list of employers
    //   if (!userRoles.includes("admin")) {
    //     set.status = 403;
    //     return { success: false, error: "Only admins can view employers" };
    //   }

    //   try {
    //     const page = parseInt(query.page || "1");
    //     const limit = parseInt(query.limit || "10");
    //     const search = query.search; // Search by name or email
    //     const offset = (page - 1) * limit;
    //     const statusFilter = query.status;

    //     // Step 1: Get users with role = "employer"
    //     const { data: authUsers, error: authError } =
    //       await supabase.auth.admin.listUsers({
    //         page,
    //         perPage: 1000, // Get enough users to filter
    //       });

    //     if (authError) {
    //       set.status = 500;
    //       return { success: false, error: authError.message };
    //     }

    //     // Step 2: Filter only employers
    //     let employerUsers = authUsers.users.filter((u) =>
    //       u.user_metadata?.roles?.includes("employer")
    //     );

    //     // Step 3: Apply search filter
    //     if (search) {
    //       employerUsers = employerUsers.filter(
    //         (u) =>
    //           u.user_metadata?.name
    //             ?.toLowerCase()
    //             .includes(search.toLowerCase()) ||
    //           u.email?.toLowerCase().includes(search.toLowerCase())
    //       );
    //     }

    //     const total = employerUsers.length;
    //     const paginated = employerUsers.slice(offset, offset + limit);

    //     // Step 4: Enrich with data from the "employer" table
    //     const enrichedEmployers = await Promise.all(
    //       paginated.map(async (authUser) => {
    //         const { data, error } = await supabase
    //           .from("employer")
    //           .select("*")
    //           .eq("id", authUser.id)
    //           .single();

    //         return {
    //           id: authUser.id,
    //           email: authUser.email,
    //           name: authUser.user_metadata?.name,
    //           created_at: authUser.created_at,
    //           status: authUser.user_metadata?.status,
    //           ...data, // may include contact, photo, etc.
    //         };
    //       })
    //     );

    //     return {
    //       success: true,
    //       data: enrichedEmployers,
    //       pagination: {
    //         page,
    //         limit,
    //         total,
    //         totalPages: Math.ceil(total / limit),
    //       },
    //     };
    //   } catch (err) {
    //     console.error("Error fetching employers:", err);
    //     set.status = 500;
    //     return { success: false, error: "Internal server error", details: err };
    //   }
    // })

    // GET /employees/:id - Get a single employee by ID

    /// teste code from chatgpt
    .get("/", async ({ query, set, request }) => {
      const user = (request as any).user as SupabaseUser;
      const userRoles = user.user_metadata?.roles || [];

      if (!userRoles.includes("admin")) {
        set.status = 403;
        return { success: false, error: "Only admins can view employers" };
      }

      try {
        const page = parseInt(query.page || "1");
        const limit = parseInt(query.limit || "10");
        const offset = (page - 1) * limit;
        const search = query.search?.toLowerCase();
        const statusFilter = query.contact;

        // Step 1: Query employer table with optional status + search filters
        let employerQuery = supabase.from("employer").select(`
    id,
    contact,
    details,
    photo,
    start_date,
    users ( id, email, name ,status)
  `);
        // .range(offset, offset + limit - 1);

        if (statusFilter) {
          employerQuery = employerQuery.eq("status", statusFilter);
        }

        if (search) {
          employerQuery = employerQuery.or(
            `status.ilike.%${search}%,details.ilike.%${search}%`
          );
          // Adjust the fields if needed to include searchable ones like name or email (see below)
        }

        const { data: employerRows, error: employerError } =
          await employerQuery;

        if (employerError) {
          set.status = 500;
          return { success: false, error: employerError.message };
        }

        // Step 2: Fetch auth data for those specific employer IDs
        const ids = employerRows.map((e) => e.id);

        const { data: authUsers, error: authError } =
          await supabase.auth.admin.listUsers({
            page: 1,
            perPage: 1000,
          });

        if (authError) {
          set.status = 500;
          return { success: false, error: authError.message };
        }

        // Step 3: Match auth users by ID and role = employer
        const employerUsers = authUsers.users.filter(
          (u) =>
            ids.includes(u.id) && u.user_metadata?.roles?.includes("employer")
        );

        // Step 4: Merge data
        const enriched = employerUsers.map((authUser) => {
          const employerData = employerRows.find((e) => e.id === authUser.id);
          console.log(employerUsers);
          console.log("********************************");
          // console.log(enriched);
          return {
            id: authUser.id,
            email: authUser.email,
            name: authUser.user_metadata?.name,
            created_at: authUser.created_at,
            status: authUser.user_metadata?.status,
            ...employerData,
          };
        });

        return {
          success: true,
          data: enriched,
          pagination: {
            page,
            limit,
            total: enriched.length,
            totalPages: Math.ceil(enriched.length / limit),
          },
        };
      } catch (err) {
        console.error("Error fetching employers:", err);
        set.status = 500;
        return { success: false, error: "Internal server error", details: err };
      }
    })

    /// end tested code from chatgpt
    .get("/:id", async ({ params, set, request }) => {
      const user = (request as any).user as SupabaseUser;

      try {
        // Get user from auth
        const { data: authUser, error: authError } =
          await supabase.auth.admin.getUserById(params.id);

        if (authError || !authUser?.user) {
          set.status = 404;
          return { success: false, error: "Employee not found" };
        }

        const userRole = authUser.user.user_metadata?.roles?.[0];
        let additionalData = {};

        // Get additional data from role-specific table
        if (userRole && userRole !== "admin") {
          const { data, error } = await supabase
            .from(userRole)
            .select("*")
            .eq("id", params.id)
            .single();

          if (!error && data) {
            additionalData = data;
          }
        }

        const employee = {
          id: authUser.user.id,
          email: authUser.user.email,
          created_at: authUser.user.created_at,
          user_metadata: authUser.user.user_metadata,
          ...additionalData,
        };

        return { success: true, data: employee };
      } catch (err) {
        console.error("Error fetching employee:", err);
        set.status = 500;
        return { success: false, error: "Internal server error", details: err };
      }
    })

    // PUT /employees/:id - Update employee (matches Flutter updateUser function)
    .put(
      "/:id",
      async ({ body, params, set, request }) => {
        const user = (request as any).user as SupabaseUser;
        const userRoles = user.user_metadata?.roles || [];
        const isAdmin = userRoles.includes("admin");
        const isSelf = user.id === params.id;

        const {
          role,
          name,
          contact,
          details,
          status,
          start_date,
          photo,
          email,
        } = body;

        // Helper function for contact validation
        const isValidContact = (contact: string): boolean => {
          // Phone number validation - adjust regex as needed
          const phoneRegex = /^[\+]?[1-9][\d]{0,15}$/;
          return phoneRegex.test(contact.replace(/[\s\-\(\)]/g, ""));
        };

        // Helper function for email validation
        const isValidEmail = (email: string): boolean => {
          const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
          return emailRegex.test(email);
        };

        try {
          // Input validation
          if (name !== undefined && name.trim() === "") {
            set.status = 400;
            return {
              success: false,
              error: "Validation failed: Name cannot be empty",
            };
          }

          if (contact !== undefined && !isValidContact(contact)) {
            set.status = 400;
            return {
              success: false,
              error: "Validation failed: Invalid contact format",
            };
          }

          if (email !== undefined && !isValidEmail(email)) {
            set.status = 400;
            return {
              success: false,
              error: "Validation failed: Invalid email format",
            };
          }

          // Authorization checks
          if (!isAdmin && !isSelf) {
            set.status = 403;
            return {
              success: false,
              error:
                "Unauthorized: Only admins or the user themselves can update this profile",
            };
          }

          if (!isAdmin && (start_date !== undefined || status !== undefined)) {
            set.status = 403;
            return {
              success: false,
              error:
                "Unauthorized: Only admins can update start_date or status",
            };
          }

          // Get current user data
          const { data: currentUser, error: currentUserError } =
            await supabase.auth.admin.getUserById(params.id);

          if (currentUserError || !currentUser?.user) {
            set.status = 404;
            return { success: false, error: "User not found" };
          }

          const userRole = role || currentUser.user.user_metadata?.roles?.[0];
          let photoUrl = currentUser.user.user_metadata?.photo;

          // Prepare updates for different tables
          const userUpdates: any = {};
          const employerUpdates: any = {};

          // Update auth.users (email and user_metadata) - only for self updates
          if ((email !== undefined || name !== undefined) && isSelf) {
            const updateAttributes: any = {};

            if (email !== undefined) {
              updateAttributes.email = email.trim();
            }

            if (name !== undefined) {
              updateAttributes.user_metadata = {
                ...currentUser.user.user_metadata,
                name: name.trim(),
              };
            }

            const { error: authUpdateError } =
              await supabase.auth.admin.updateUserById(
                params.id,
                updateAttributes
              );

            if (authUpdateError) {
              set.status = 500;
              return {
                success: false,
                error: "Failed to update auth user",
                details: authUpdateError.message,
              };
            }
          }

          // Update public.users (name and status)
          if (name !== undefined) {
            userUpdates.name = name.trim();
          }

          if (status !== undefined && isAdmin) {
            userUpdates.status = status;
          }

          // Update role-specific table (employer)
          if (userRole === "employer") {
            if (contact !== undefined) {
              employerUpdates.contact = contact.trim();
            }

            if (details !== undefined) {
              employerUpdates.details = details.trim();
            }

            // Handle photo upload
            if (photo) {
              const photoPath = `${userRole}/${params.id}/${Date.now()}.jpg`;
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

              photoUrl = supabase.storage
                .from("employees")
                .getPublicUrl(photoPath).data.publicUrl;
              employerUpdates.photo = photoUrl;
            }

            if (isAdmin && start_date !== undefined) {
              employerUpdates.start_date = start_date;
            }
          }

          // Apply updates to public.users
          if (Object.keys(userUpdates).length > 0) {
            const { error: userUpdateError } = await supabase
              .from("users")
              .update(userUpdates)
              .eq("id", params.id);

            if (userUpdateError) {
              set.status = 500;
              return {
                success: false,
                error: "Failed to update users table",
                details: userUpdateError.message,
              };
            }
          }

          // Apply updates to role-specific table
          if (Object.keys(employerUpdates).length > 0 && userRole) {
            const { error: roleUpdateError } = await supabase
              .from(userRole)
              .update(employerUpdates)
              .eq("id", params.id);

            if (roleUpdateError) {
              set.status = 500;
              return {
                success: false,
                error: `Failed to update ${userRole} table`,
                details: roleUpdateError.message,
              };
            }
          }

          // Update user_metadata if needed (for admin updates)
          if (
            isAdmin &&
            (name !== undefined ||
              photoUrl !== currentUser.user.user_metadata?.photo ||
              status !== undefined ||
              start_date !== undefined)
          ) {
            const updatedMetadata = {
              ...currentUser.user.user_metadata,
              ...(name !== undefined && { name: name.trim() }),
              ...(photoUrl && { photo: photoUrl }),
              ...(status !== undefined && { status }),
              ...(start_date !== undefined && { start_date }),
            };

            const { error: metadataUpdateError } =
              await supabase.auth.admin.updateUserById(params.id, {
                user_metadata: updatedMetadata,
              });

            if (metadataUpdateError) {
              console.warn(
                "Failed to update user metadata:",
                metadataUpdateError
              );
            }
          }

          console.log(`Updated user: ${params.id}`);
          return {
            success: true,
            message: "User updated successfully",
            data: {
              id: params.id,
              updated_fields: {
                ...userUpdates,
                ...employerUpdates,
                ...(email !== undefined && { email }),
              },
            },
          };
        } catch (err) {
          console.error("updateUser() failed:", err);
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
          role: t.Optional(t.String()),
          name: t.Optional(t.String()),
          contact: t.Optional(t.String()),
          details: t.Optional(t.String()),
          status: t.Optional(t.String()),
          start_date: t.Optional(t.String()),
          photo: t.Optional(t.File()),
          email: t.Optional(t.String()),
        }),
      }
    )

    // PATCH /employees/:id/status - Update employee status only
    .patch(
      "/:id/status",
      async ({ body, params, set, request }) => {
        const user = (request as any).user as SupabaseUser;
        const userRoles = user.user_metadata?.roles || [];

        // Only admins and employers can update status
        if (!userRoles.includes("admin") && !userRoles.includes("employer")) {
          set.status = 403;
          return { success: false, error: "Insufficient permissions" };
        }

        const { status } = body;

        try {
          // Get current user data
          const { data: currentUser, error: currentUserError } =
            await supabase.auth.admin.getUserById(params.id);

          if (currentUserError || !currentUser?.user) {
            set.status = 404;
            return { success: false, error: "Employee not found" };
          }

          // Update user metadata
          const updatedMetadata = {
            ...currentUser.user.user_metadata,
            status,
          };

          const { error: updateError } =
            await supabase.auth.admin.updateUserById(params.id, {
              user_metadata: updatedMetadata,
            });

          if (updateError) {
            set.status = 500;
            return {
              success: false,
              error: "Failed to update employee status",
              details: updateError.message,
            };
          }

          return {
            success: true,
            message: "Employee status updated successfully",
            data: { id: params.id, status },
          };
        } catch (err) {
          console.error("Error updating employee status:", err);
          set.status = 500;
          return {
            success: false,
            error: "Internal server error",
            details: err,
          };
        }
      },
      {
        body: t.Object({
          status: t.String(),
        }),
      }
    )

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

    // Skills Management API Endpoints

// GET /skills/categories - Get all skill categories
.get("/skills/categories", async ({ set }) => {
  try {
    const { data, error } = await supabase
      .from("skill_categories")
      .select("*")
      .order("name");

    if (error) {
      set.status = 400;
      return { success: false, error: error.message };
    }

    return { success: true, data };
  } catch (err) {
    console.error("Error fetching skill categories:", err);
    set.status = 500;
    return { success: false, error: "Internal server error" };
  }
})

// GET /skills - Get all skills with categories
.get("/skills", async ({ query, set }) => {
  const { category_id } = query;
  
  try {
    let queryBuilder = supabase
      .from("skills")
      .select(`
        *,
        skill_categories(id, name)
      `)
      .order("name");

    if (category_id) {
      queryBuilder = queryBuilder.eq("category_id", category_id);
    }

    const { data, error } = await queryBuilder;

    if (error) {
      set.status = 400;
      return { success: false, error: error.message };
    }

    return { success: true, data };
  } catch (err) {
    console.error("Error fetching skills:", err);
    set.status = 500;
    return { success: false, error: "Internal server error" };
  }
})

// POST /skills - Create new skill (Admin only)
.post("/skills", async ({ body, headers, set }) => {
  const { name, category_id, description } = body;

  // Get current user info from Authorization header
  const token = headers.authorization?.replace("Bearer ", "");
  const { data: userInfo, error: userInfoError } = await supabase.auth.getUser(token);

  if (userInfoError || !userInfo?.user) {
    set.status = 401;
    return { success: false, error: "Unauthorized" };
  }

  // Check if user is admin
  const { data: roleData, error: roleError } = await supabase
    .from("user_roles")
    .select("role_id")
    .eq("user_id", userInfo.user.id)
    .single();

  if (roleError || roleData?.role_id !== "admin") {
    set.status = 403;
    return { success: false, error: "Only admins can create skills" };
  }

  try {
    const { data, error } = await supabase
      .from("skills")
      .insert({
        name: name.trim(),
        category_id,
        description: description?.trim()
      })
      .select(`
        *,
        skill_categories(id, name)
      `)
      .single();

    if (error) {
      set.status = 400;
      return { success: false, error: error.message };
    }

    return { success: true, data };
  } catch (err) {
    console.error("Error creating skill:", err);
    set.status = 500;
    return { success: false, error: "Internal server error" };
  }
}, {
  body: t.Object({
    name: t.String(),
    category_id: t.String(),
    description: t.Optional(t.String())
  })
})

// PUT /skills/:id - Update skill (Admin only)
.put("/skills/:id", async ({ params, body, headers, set }) => {
  const { id } = params;
  const { name, category_id, description } = body;

  // Get current user info from Authorization header
  const token = headers.authorization?.replace("Bearer ", "");
  const { data: userInfo, error: userInfoError } = await supabase.auth.getUser(token);

  if (userInfoError || !userInfo?.user) {
    set.status = 401;
    return { success: false, error: "Unauthorized" };
  }

  // Check if user is admin
  const { data: roleData, error: roleError } = await supabase
    .from("user_roles")
    .select("role_id")
    .eq("user_id", userInfo.user.id)
    .single();

  if (roleError || roleData?.role_id !== "admin") {
    set.status = 403;
    return { success: false, error: "Only admins can update skills" };
  }

  try {
    const { data, error } = await supabase
      .from("skills")
      .update({
        name: name.trim(),
        category_id,
        description: description?.trim()
      })
      .eq("id", id)
      .select(`
        *,
        skill_categories(id, name)
      `)
      .single();

    if (error) {
      set.status = 400;
      return { success: false, error: error.message };
    }

    return { success: true, data };
  } catch (err) {
    console.error("Error updating skill:", err);
    set.status = 500;
    return { success: false, error: "Internal server error" };
  }
}, {
  body: t.Object({
    name: t.String(),
    category_id: t.String(),
    description: t.Optional(t.String())
  })
})

// DELETE /skills/:id - Delete skill (Admin only)
.delete("/skills/:id", async ({ params, headers, set }) => {
  const { id } = params;

  // Get current user info from Authorization header
  const token = headers.authorization?.replace("Bearer ", "");
  const { data: userInfo, error: userInfoError } = await supabase.auth.getUser(token);

  if (userInfoError || !userInfo?.user) {
    set.status = 401;
    return { success: false, error: "Unauthorized" };
  }

  // Check if user is admin
  const { data: roleData, error: roleError } = await supabase
    .from("user_roles")
    .select("role_id")
    .eq("user_id", userInfo.user.id)
    .single();

  if (roleError || roleData?.role_id !== "admin") {
    set.status = 403;
    return { success: false, error: "Only admins can delete skills" };
  }

  try {
    const { error } = await supabase
      .from("skills")
      .delete()
      .eq("id", id);

    if (error) {
      set.status = 400;
      return { success: false, error: error.message };
    }

    return { success: true, message: "Skill deleted successfully" };
  } catch (err) {
    console.error("Error deleting skill:", err);
    set.status = 500;
    return { success: false, error: "Internal server error" };
  }
})

// GET /employees/:id/skills - Get employee skills
.get("/:id/skills", async ({ params, headers, set }) => {
  const { id: employeeId } = params;

  // Get current user info from Authorization header
  const token = headers.authorization?.replace("Bearer ", "");
  const { data: userInfo, error: userInfoError } = await supabase.auth.getUser(token);

  if (userInfoError || !userInfo?.user) {
    set.status = 401;
    return { success: false, error: "Unauthorized" };
  }

  // Check if user is admin or accessing their own skills
  const { data: roleData } = await supabase
    .from("user_roles")
    .select("role_id")
    .eq("user_id", userInfo.user.id)
    .single();

  const isAdmin = roleData?.role_id === "admin";
  const isSelf = userInfo.user.id === employeeId;

  if (!isAdmin && !isSelf) {
    set.status = 403;
    return { success: false, error: "Access denied" };
  }

  try {
    const { data, error } = await supabase
      .from("employee_skills")
      .select(`
        *,
        skills(
          *,
          skill_categories(id, name)
        )
      `)
      .eq("employee_id", employeeId)
      .order("created_at", { ascending: false });

    if (error) {
      set.status = 400;
      return { success: false, error: error.message };
    }

    return { success: true, data };
  } catch (err) {
    console.error("Error fetching employee skills:", err);
    set.status = 500;
    return { success: false, error: "Internal server error" };
  }
})

// POST /:id/skills - Add skill to employee (Admin only)
.post("/:id/skills", async ({ params, body, headers, set }) => {
  const { id: employeeId } = params;
  const { 
    skill_id, 
    proficiency_level, 
    years_of_experience, 
    certification_url, 
    certification_name, 
    notes 
  } = body;

  // Get current user info from Authorization header
  const token = headers.authorization?.replace("Bearer ", "");
  const { data: userInfo, error: userInfoError } = await supabase.auth.getUser(token);

  if (userInfoError || !userInfo?.user) {
    set.status = 401;
    return { success: false, error: "Unauthorized" };
  }

  // Check if user is admin
  const { data: roleData, error: roleError } = await supabase
    .from("user_roles")
    .select("role_id")
    .eq("user_id", userInfo.user.id)
    .single();

  if (roleError || roleData?.role_id !== "admin") {
    set.status = 403;
    return { success: false, error: "Only admins can add skills to employees" };
  }

  try {
    const { data, error } = await supabase
      .from("employee_skills")
      .insert({
        employee_id: employeeId,
        skill_id,
        proficiency_level: proficiency_level || "beginner",
        years_of_experience: years_of_experience || 0,
        certification_url: certification_url?.trim(),
        certification_name: certification_name?.trim(),
        notes: notes?.trim()
      })
      .select(`
        *,
        skills(
          *,
          skill_categories(id, name)
        )
      `)
      .single();

    if (error) {
      set.status = 400;
      return { success: false, error: error.message };
    }

    return { success: true, data };
  } catch (err) {
    console.error("Error adding employee skill:", err);
    set.status = 500;
    return { success: false, error: "Internal server error" };
  }
}, {
  body: t.Object({
    skill_id: t.String(),
    proficiency_level: t.Optional(t.Union([
      t.Literal("beginner"),
      t.Literal("intermediate"), 
      t.Literal("advanced"),
      t.Literal("expert")
    ])),
    years_of_experience: t.Optional(t.Number()),
    certification_url: t.Optional(t.String()),
    certification_name: t.Optional(t.String()),
    notes: t.Optional(t.String())
  })
})

// PUT /:id/skills/:skillId - Update employee skill (Admin only)
.put("/:id/skills/:skillId", async ({ params, body, headers, set }) => {
  const { id: employeeId, skillId } = params;
  const { 
    proficiency_level, 
    years_of_experience, 
    certification_url, 
    certification_name, 
    notes 
  } = body;

  // Get current user info from Authorization header
  const token = headers.authorization?.replace("Bearer ", "");
  const { data: userInfo, error: userInfoError } = await supabase.auth.getUser(token);

  if (userInfoError || !userInfo?.user) {
    set.status = 401;
    return { success: false, error: "Unauthorized" };
  }

  // Check if user is admin
  const { data: roleData, error: roleError } = await supabase
    .from("user_roles")
    .select("role_id")
    .eq("user_id", userInfo.user.id)
    .single();

  if (roleError || roleData?.role_id !== "admin") {
    set.status = 403;
    return { success: false, error: "Only admins can update employee skills" };
  }

  try {
    const { data, error } = await supabase
      .from("employee_skills")
      .update({
        proficiency_level,
        years_of_experience,
        certification_url: certification_url?.trim(),
        certification_name: certification_name?.trim(),
        notes: notes?.trim()
      })
      .eq("employee_id", employeeId)
      .eq("skill_id", skillId)
      .select(`
        *,
        skills(
          *,
          skill_categories(id, name)
        )
      `)
      .single();

    if (error) {
      set.status = 400;
      return { success: false, error: error.message };
    }

    return { success: true, data };
  } catch (err) {
    console.error("Error updating employee skill:", err);
    set.status = 500;
    return { success: false, error: "Internal server error" };
  }
}, {
  body: t.Object({
    proficiency_level: t.Optional(t.Union([
      t.Literal("beginner"),
      t.Literal("intermediate"), 
      t.Literal("advanced"),
      t.Literal("expert")
    ])),
    years_of_experience: t.Optional(t.Number()),
    certification_url: t.Optional(t.String()),
    certification_name: t.Optional(t.String()),
    notes: t.Optional(t.String())
  })
})

// DELETE /:id/skills/:skillId - Remove skill from employee (Admin only)
.delete("/:id/skills/:skillId", async ({ params, headers, set }) => {
  const { id: employeeId, skillId } = params;

  // Get current user info from Authorization header
  const token = headers.authorization?.replace("Bearer ", "");
  const { data: userInfo, error: userInfoError } = await supabase.auth.getUser(token);

  if (userInfoError || !userInfo?.user) {
    set.status = 401;
    return { success: false, error: "Unauthorized" };
  }

  // Check if user is admin
  const { data: roleData, error: roleError } = await supabase
    .from("user_roles")
    .select("role_id")
    .eq("user_id", userInfo.user.id)
    .single();

  if (roleError || roleData?.role_id !== "admin") {
    set.status = 403;
    return { success: false, error: "Only admins can remove employee skills" };
  }

  try {
    const { error } = await supabase
      .from("employee_skills")
      .delete()
      .eq("employee_id", employeeId)
      .eq("skill_id", skillId);

    if (error) {
      set.status = 400;
      return { success: false, error: error.message };
    }

    return { success: true, message: "Skill removed from employee successfully" };
  } catch (err) {
    console.error("Error removing employee skill:", err);
    set.status = 500;
    return { success: false, error: "Internal server error" };
  }
})
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
          .select(
            `
            *
          `
          )
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
          .select(
            `
           *,
        project_employees(
          id,
          role,
          assigned_at,
          employer(id, contact, details, photo, start_date
          ,users(id,email,name)
          )
        )
        
      `
          )
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

    .post(
      "/",
      async ({ body, set, request }) => {
        const user = (request as any).user as SupabaseUser;

        // Check if user is admin
        if (!user.user_metadata?.roles?.includes("admin")) {
          set.status = 403;
          return { success: false, error: "Only admins can create projects" };
        }

        const {
          id, // ID optionnel du frontend
          name,
          description,
          startDate,
          endDate,
          size,
          scope,
          status,
          employer_assignments, // Champ pour les assignations d'employés avec rôles
        } = body;

        // Debug: Log des données reçues
        console.log("Body received:", body);
        console.log("Employer assignments:", employer_assignments);

        try {
          // Validation des données requises
          if (!name || !description) {
            set.status = 400;
            return {
              success: false,
              error: "Name and description are required",
            };
          }

          // Validation des assignations d'employés (optionnel)
          if (employer_assignments && !Array.isArray(employer_assignments)) {
            set.status = 400;
            return {
              success: false,
              error: "employer_assignments must be an array",
            };
          }

          // Début de la transaction
          // Insertion du projet
          const { data: projectData, error: projectError } = await supabase
            .from("projects")
            .insert([
              {
                ...(id && { id }), // Inclure l'ID seulement s'il est fourni
                name,
                description,
                start_date: startDate,
                end_date: endDate,
                size,
                scope,
                status: status || "planning",
                created_by: user.id,
              },
            ])
            .select()
            .single();

          if (projectError) {
            set.status = 400;
            return { success: false, error: projectError.message };
          }

          // Si des employés sont assignés, les ajouter à la table project_employees
          if (employer_assignments && employer_assignments.length > 0) {
            console.log(
              "Creating project-employee assignments for project:",
              projectData.id
            );

            const projectEmployeesData = employer_assignments.map(
              (assignment: any) => ({
                project_id: projectData.id,
                employee_id: assignment.employer_id,
                assigned_at: new Date().toISOString(),
                role: assignment.role || "member",
              })
            );

            console.log(
              "Project employees data to insert:",
              projectEmployeesData
            );

            const { data: assignmentData, error: assignmentError } =
              await supabase
                .from("project_employees")
                .insert(projectEmployeesData)
                .select();

            if (assignmentError) {
              console.error("Assignment error:", assignmentError);

              set.status = 201;
              return {
                success: true,
                data: projectData,
                message:
                  "Project created successfully but employee assignment failed",
                warning: assignmentError.message,
              };
            }

            console.log("Assignment successful:", assignmentData);
          }

          // Récupérer le projet avec les employés assignés pour la réponse
          const { data: completeProjectData, error: fetchError } =
            await supabase
              .from("projects")
              .select(
                `
              *,
              project_employees (
                employee_id,
                assigned_at,
                employee:users!project_employees_employee_id_fkey (
                  id,
                  email,
                  name
                )
              )
            `
              )
              .eq("id", projectData.id)
              .single();

          if (fetchError) {
            console.error("Fetch error:", fetchError);
            // Retourner les données de base même si la récupération complète échoue
            set.status = 201;
            return {
              success: true,
              data: projectData,
              message: "Project created successfully",
            };
          }

          set.status = 201;
          return {
            success: true,
            data: completeProjectData,
            message:
              "Project created successfully" +
              (employer_assignments && employer_assignments.length > 0
                ? ` with ${employer_assignments.length} employee(s) assigned`
                : ""),
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
      },
      {
        body: t.Object({
          id: t.Optional(t.String()), // ID optionnel
          name: t.String(),
          description: t.String(),
          startDate: t.Optional(t.String()),
          endDate: t.Optional(t.String()),
          size: t.Optional(t.String()),
          scope: t.Optional(t.String()),
          status: t.Optional(t.String()),
          employer_assignments: t.Optional(
            t.Array(
              t.Object({
                employer_id: t.String(),
                role: t.String(),
              })
            )
          ), // Nouveau champ pour les assignations avec rôles
        }),
      }
    )
    // PUT /projects/:id - Update project
    .put(
      "/:id",
      async ({ body, params, set, request }) => {
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
          employeeIds = [],
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
              const employeeAssignments = employeeIds.map(
                (employeeId: any) => ({
                  project_id: params.id,
                  employee_id: employeeId,
                })
              );

              await supabase
                .from("project_employees")
                .insert(employeeAssignments);
            }
          }

          return {
            success: true,
            data,
            message: "Project updated successfully",
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
      },
      {
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
      }
    )

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
          data,
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
);



app.listen(3000, () => {
  console.log("✅ Server running on http://localhost:3000");
});

type EmployerWithUser = {
  id: string;
  contact: string;
  details: string | null;
  photo: string;
  start_date: string;
  users: {
    id: string;
    email: string;
    name: string;
    status: string;
  };
};
