// import 'package:flutter/material.dart';
// import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

// class SearchableDropdown2 extends StatefulWidget {
//   const SearchableDropdown2({
//     Key? key,
//     required this.items,
//     this.hintText = 'Search...',
//     this.onSelected,
//     this.initialSelectedItem,
//   }) : super(key: key);

//   final List<String> items;
//   final String hintText;
//   final Function(String)? onSelected;
//   final String? initialSelectedItem;

//   @override
//   State<SearchableDropdown2> createState() => _SearchableDropdownState2();
// }

// class _SearchableDropdownState2 extends State<SearchableDropdown2> {
//   late List<String> filteredItems;
//   final SearchController _searchController = SearchController();
//   final ItemScrollController _scrollController = ItemScrollController();
//   String? selectedItem;
//   String previousText = '';
//   bool suppressFiltering = true;

//   @override
//   void initState() {
//     super.initState();
//     // Inicializar a lista filtrada com todos os itens disponíveis.
//     filteredItems = widget.items;
//     selectedItem = widget.initialSelectedItem;

//     _searchController.addListener(() {
//       if (!suppressFiltering && _searchController.text != previousText) {
//         previousText = _searchController.text;
//         _filterItems(_searchController.text);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _filterItems(String query) {
//     filteredItems =
//         query.isEmpty
//             ? widget.items
//             : widget.items
//                 .where(
//                   (item) =>
//                       item.toLowerCase().contains(query.trim().toLowerCase()),
//                 )
//                 .toList();
//   }

//   void _onItemSelected(String item) {
//     suppressFiltering = true;
//     _searchController.closeView(item);
//     if (widget.onSelected != null) {
//       widget.onSelected!(item);
//     }

//     selectedItem = item;
//     previousText = _searchController.text;
//   }

//   void _scrollToSelectedItem() {
//     if (selectedItem != null && _searchController.isOpen) {
//       final index = filteredItems.indexOf(selectedItem!);
//       if (index >= 0) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _scrollController.scrollTo(
//             index: index,
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.ease,
//           );
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 300, // Ajuste conforme necessário
//       child: SearchAnchor.bar(
//         barHintText: widget.hintText,
//         searchController: _searchController,
//         isFullScreen: false,
//         onTap: () {
//           setState(() {
//             filteredItems = widget.items; // Resetar a lista ao abrir.
//             suppressFiltering = false;
//           });
//         },
//         suggestionsBuilder: (context, controller) => [],
//         viewBuilder: (_) {
//           _scrollToSelectedItem();

//           // Retorna o widget ListView diretamente
//           return Material(
//             child: ScrollablePositionedList.builder(
//               itemScrollController: _scrollController,
//               itemCount: filteredItems.length,
//               itemBuilder: (context, index) {
//                 final item = filteredItems[index];
//                 return ListTile(
//                   title: Text(item),
//                   onTap: () {
//                     _onItemSelected(item);
//                   },
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
