// import 'package:flutter/material.dart';
// import 'package:health_app/app_colors.dart';
// import 'package:health_app/ibu/diskusi/add_diskusi.dart';
// import 'package:health_app/ibu/diskusi/open_diskusi_page.dart';

// class DiskusiBidan extends StatefulWidget {
//   const DiskusiBidan({Key? key}) : super(key: key);

//   @override
//   State<DiskusiBidan> createState() => _DiskusiBidanState();
// }

// class _DiskusiBidanState extends State<DiskusiBidan> {
//   final List<Map<String, dynamic>> _allChats = const [
//     {
//       'name': 'R1yaping',
//       'sender': 'wow',
//       'message': 'hidup joko...',
//       'imageUrl': '',
//     },
//     {
//       'name': 'Sunda Empire',
//       'sender': 'kdd',
//       'message': 'hidupp cahu',
//       'imageUrl': '',
//     },
//     {
//       'name': 'Mapia sawah',
//       'sender': 'guzzz',
//       'message': 'hidup blonde',
//       'imageUrl': '',
//     },
//     // Tambahan data lainnya...
//   ];

//   List<Map<String, dynamic>> _filteredChats = [];

//   final TextEditingController _searchController = TextEditingController();
//   final List<bool> _isHovering = [];

//   @override
//   void initState() {
//     super.initState();
//     _filteredChats = List.from(_allChats);
//     _isHovering.addAll(List.generate(_allChats.length, (index) => false));
//     _searchController.addListener(_onSearchChanged);
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _onSearchChanged() {
//     final keyword = _searchController.text.toLowerCase();
//     setState(() {
//       _filteredChats = _allChats
//           .where(
//             (chat) =>
//                 chat['name'].toLowerCase().contains(keyword) ||
//                 chat['message'].toLowerCase().contains(keyword),
//           )
//           .toList();
//     });
//   }

//   void _onEntered(bool isHovering, int index) {
//     if (index < _isHovering.length) {
//       setState(() {
//         _isHovering[index] = isHovering;
//       });
//     }
//   }

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
//                   children: const [
//                     Text(
//                       'Diskusi',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 20,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 10,
//                 ),
//                 child: TextField(
//                   controller: _searchController,
//                   decoration: InputDecoration(
//                     hintText: 'Cari grup atau pesan...',
//                     prefixIcon: const Icon(
//                       Icons.search,
//                       color: AppColors.buttonBackground,
//                     ),
//                     filled: true,
//                     fillColor: AppColors.inputFill,
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: const BorderSide(
//                         color: AppColors
//                             .inputBorderFocused, // hijau redup (misalnya: Light Green 400)
//                         width: 1.5,
//                       ),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: const BorderSide(
//                         color: AppColors.inputBorder, // hijau terang
//                         width: 2,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: ListView.builder(
//                   padding: const EdgeInsets.only(bottom: 80),
//                   itemCount: _filteredChats.length,
//                   itemBuilder: (context, index) {
//                     final chat = _filteredChats[index];
//                     final sender = chat['sender'];
//                     final message = chat['message'];

//                     return MouseRegion(
//                       onEnter: (event) => _onEntered(true, index),
//                       onExit: (event) => _onEntered(false, index),
//                       child: ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor: AppColors.inputBorder,
//                           child: const Icon(Icons.groups, color: Colors.white),
//                         ),
//                         title: Text(
//                           chat['name'],
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black,
//                             fontSize: 16,
//                           ),
//                         ),
//                         subtitle: Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               '$sender: ',
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                             Expanded(
//                               child: Text(
//                                 message,
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: const TextStyle(
//                                   color: AppColors.labelText,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                         ),
//                         tileColor: _isHovering[index]
//                             ? AppColors.inputFill
//                             : AppColors.background,
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const OpenDiskusi(),
//                             ),
//                           );
//                         },
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),

//           // Floating Action Button
//           Positioned(
//             bottom: 16,
//             right: 16,
//             child: FloatingActionButton(
//               backgroundColor: AppColors.buttonBackground,
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const AddGroupPage()),
//                 );
//               },
//               child: const Icon(Icons.add, color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
