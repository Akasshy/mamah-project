// import 'package:flutter/material.dart';
// import 'package:health_app/app_colors.dart';
// import 'package:health_app/ibu/konsultasi/open_konsultasi_page.dart';

// class KonsultasiBidan extends StatefulWidget {
//   const KonsultasiBidan({Key? key}) : super(key: key); // Added Key? key

//   @override
//   State<KonsultasiBidan> createState() => _KonsultasiBidanState();
// }

// class _KonsultasiBidanState extends State<KonsultasiBidan> {
//   final List<Map<String, dynamic>> chats = const [
//     {
//       'name': 'Sung Hunter',
//       'message': 'hidup joko...',
//       'imageUrl': 'images/pp.jpg',
//     },
//     {'name': 'Sunda Empire', 'message': 'hidupp cahu', 'imageUrl': ''},
//     {'name': 'Mapia sawah', 'message': 'hidup blonde', 'imageUrl': ''},
//   ];

//   final List<bool> _isHovering = List.generate(3, (index) => false);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(70),
//         child: Container(
//           color: Colors.white,
//           child: Center(
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(maxWidth: 1200),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Row(
//                   children: [
//                     // Text di kiri
//                     const Text(
//                       'Konsultasi',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 20,
//                         color: Colors.black,
//                       ),
//                     ),
//                     const Spacer(),
//                     // Profil kanan
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.symmetric(vertical: 0),
//         itemCount: chats.length,
//         itemBuilder: (context, index) {
//           final chat = chats[index];
//           final String imagePath = chat['imageUrl'];
//           final String message = chat['message'];

//           return MouseRegion(
//             onEnter: (event) => _onEntered(true, index),
//             onExit: (event) => _onEntered(false, index),
//             child: ListTile(
//               leading: imagePath.isNotEmpty
//                   ? CircleAvatar(
//                       backgroundImage: AssetImage(imagePath),
//                       backgroundColor: Colors.grey[300],
//                     )
//                   : CircleAvatar(
//                       backgroundColor: AppColors.inputBorder,
//                       child: const Icon(Icons.person, color: Colors.white),
//                     ),
//               title: Text(
//                 chat['name'],
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                   fontSize: 16,
//                 ),
//               ),
//               subtitle: Text(
//                 message,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(color: AppColors.labelText),
//               ),
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16),
//               tileColor: _isHovering[index]
//                   ? AppColors.inputFill
//                   : AppColors.background,
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const OpenKonsultasi(),
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void _onEntered(bool isHovering, int index) {
//     setState(() {
//       _isHovering[index] = isHovering;
//     });
//   }
// }
