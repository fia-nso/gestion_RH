// import 'package:flutter/material.dart';
// import 'package:frontend/controller_provider/update_provider.dart';
// import 'package:frontend/l10n/generated/app_localizations.dart';
// import 'package:provider/provider.dart';
// import '../controller_provider/auth_provider.dart';
// import '../controller_provider/locale_provider.dart';

// class EmployerDashboard extends StatelessWidget {
//   const EmployerDashboard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => EmployerUpdateController(),
//       child: const _EmployerDashboardBody(),
//     );
//   }
// }

// class _EmployerDashboardBody extends StatelessWidget {
//   const _EmployerDashboardBody({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final localeController = Provider.of<LocaleProvider>(context);
//     final controller = context.watch<EmployerUpdateController>();
//     final authController = context.watch<AuthController>();

//     var photo2 = authController.emoloyer.photo;
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(AppLocalizations.of(context)!.employer),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.language),
//             onPressed: () {
//               final newLocale = localeController.locale.languageCode == 'en'
//                   ? const Locale('ar')
//                   : const Locale('en');
//               localeController.changeLocale(newLocale);
//             },
//             tooltip: AppLocalizations.of(context)!.change_language,
//           ),
//         ],
//       ),
//       body: controller.loading
//           ? const Center(child: CircularProgressIndicator())
//           : controller.error != null
//               ? Center(child: Text(controller.error!))
//               : Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: SingleChildScrollView(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Text(
//                           '${AppLocalizations.of(context)!.bienvenue}, ${authController.emoloyer.name ?? "👤"}',
//                           style: Theme.of(context).textTheme.titleLarge,
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 20),
//                         // Display profile photo with proper null checks
//                         CircleAvatar(
//                           radius: 50,
//                           backgroundColor: Colors.grey[200],
//                           backgroundImage: photo2 != null &&
//                                   authController.emoloyer.photo!.isNotEmpty
//                               ? NetworkImage(authController.emoloyer.photo!)
//                               : null,
//                           onBackgroundImageError:
//                               authController.emoloyer.photo != null &&
//                                       authController.emoloyer.photo!.isNotEmpty
//                                   ? (exception, stackTrace) {
//                                       print('Image loading error: $exception');
//                                     }
//                                   : null,
//                           child: authController.emoloyer.photo == null ||
//                                   authController.emoloyer.photo!.isEmpty
//                               ? const Icon(Icons.person, size: 50)
//                               : null,
//                         ),
//                         const SizedBox(height: 10),
//                         TextButton(
//                           onPressed: controller.pickPhoto,
//                           child:
//                               Text(AppLocalizations.of(context)!.upload_photo),
//                         ),
//                         const SizedBox(height: 20),
//                         TextField(
//                           controller: controller.nameController,
//                           decoration: InputDecoration(
//                             labelText: AppLocalizations.of(context)!.name,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         TextField(
//                           controller: controller.contactController,
//                           decoration: InputDecoration(
//                             labelText: AppLocalizations.of(context)!.contact,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         TextField(
//                           controller: controller.detailsController,
//                           decoration: InputDecoration(
//                             labelText: 'details',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         controller.loading
//                             ? const CircularProgressIndicator()
//                             : ElevatedButton(
//                                 onPressed: controller.save,
//                                 child: Text(AppLocalizations.of(context)!.save),
//                               ),
//                         if (controller.error != null)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 16.0),
//                             child: Text(
//                               controller.error!,
//                               style: const TextStyle(
//                                 color: Colors.red,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//     );
//   }
// }
