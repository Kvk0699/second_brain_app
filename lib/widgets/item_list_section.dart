// import 'package:flutter/material.dart';
// import '../models/item_model.dart';
// import '../screens/item_list_screen.dart';
// import 'event_display_widget.dart';
// import 'note_display_widget.dart';

// class ItemListSection extends StatelessWidget {
//   final String title;
//   final List<ItemModel> items;
//   final Function(ItemModel) onItemTap;
//   final int maxItems;

//   const ItemListSection({
//     Key? key,
//     required this.title,
//     required this.items,
//     required this.onItemTap,
//     this.maxItems = 3,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final displayItems = items.take(maxItems).toList();
//     final hasMore = items.length > maxItems;
//     // final remainingCount = items.length - maxItems;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 '$title (${items.length})',
//                 style: Theme.of(context).textTheme.headlineMedium,
//               ),
//               // if (hasMore)
//               //   TextButton.icon(
//               //     onPressed: () {
//               //       Navigator.push(
//               //         context,
//               //         MaterialPageRoute(
//               //           builder: (context) => ItemListScreen(
//               //             title: title,
//               //             items: items,
//               //             onItemTap: onItemTap,
//               //           ),
//               //         ),
//               //       );
//               //     },
//               //     icon: const Icon(Icons.arrow_forward, size: 16),
//               //     label: Text(
//               //       'View all ($remainingCount more)',
//               //       style: const TextStyle(
//               //         fontSize: 14,
//               //         fontWeight: FontWeight.w500,
//               //       ),
//               //     ),
//               //   ),
//             ],
//           ),
//         ),
//         SizedBox(
//           height: MediaQuery.of(context).size.height * 0.4,
//           child: GridView.builder(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               childAspectRatio: 0.8,
//               crossAxisSpacing: 4,
//               mainAxisSpacing: 4,
//             ),
//             itemCount: displayItems.length + (hasMore ? 1 : 0),
//             itemBuilder: (context, index) {
//               if (index == displayItems.length) {
//                 // Show "View More" card at the end
//                 return TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => ItemListScreen(
//                             title: title,
//                             items: items,
//                             onItemTap: onItemTap,
//                           ),
//                         ),
//                       );
//                     },
//                     child: Row(
//                       children: [
//                         const Text('View more',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                             )),
//                         Container(
//                           padding: const EdgeInsets.all(4),
//                           margin: const EdgeInsets.only(left: 4),
//                           decoration: BoxDecoration(
//                             color: Theme.of(context).colorScheme.primary,
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             Icons.arrow_forward_ios,
//                             size: 12,
//                             color: Theme.of(context).colorScheme.onPrimary,
//                           ),
//                         ),
//                       ],
//                     ));
//               }

//               final item = displayItems[index];
//               if (item is EventModel) {
//                 return EventDisplayWidget(onItemTap: onItemTap, item: item);
//               }

//               return NoteDisplayWidget(
//                   onItemTap: onItemTap, item: item as NoteModel);
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
