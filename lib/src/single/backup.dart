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




// import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
// import 'package:simple_search_dropdown/simple_search_dropdown.dart';
// import 'package:stringr/stringr.dart';

// ///This creates the list that contains the items to be selected.
// class SingleListView<T> extends StatelessWidget {
//   SingleListView({
//     required this.addMode,
//     required this.onAddItem,
//     required this.newValueItem,
//     required this.backgroundColor,
//     required this.searchbarText,
//     required this.deleteMode,
//     required this.elevation,
//     required this.listaFiltrada,
//     required this.editMode,
//     required this.onEdit,
//     required this.onDelete,
//     required this.onPressed,
//     required this.overlayListSettings,
//     required this.dropdownwidth,
//     required this.selectedItem,
//     required this.shouldScroll,
//     required this.updateShouldScroll,
//     required this.addAditionalWidget,
//     required this.defaultAditionalWidget,
//     super.key,
//   });

//   ///Allow the user to add items to the list.
//   final bool addMode;

//   ///Function to be executed after the item was added.
//   final Function(ValueItem<T> value) onAddItem;

//   ///Function that defines how the user input transforms into a new ValueItem on the list.
//   final ValueItem<T> Function(String input)? newValueItem;

//   ///The settings for the overlay list of items.
//   final SimpleOverlaySettings overlayListSettings;
//   final Color? backgroundColor;
//   final String searchbarText;
//   final bool editMode;
//   final bool deleteMode;
//   final double elevation;
//   final List<ValueItem<T>> listaFiltrada;
//   final Function(ValueItem<T> value) onEdit;
//   final Function(ValueItem<T> value) onDelete;
//   final Function(ValueItem<T> value) onPressed;
//   final double dropdownwidth;
//   final ValueItem<T>? selectedItem;
//   final bool shouldScroll;
//   final VoidCallback updateShouldScroll;
//   final ItemScrollController scrollController = ItemScrollController();
//   final Widget? addAditionalWidget;
//   final Widget? defaultAditionalWidget;

//   ///Function to scroll the list to the selected item
//   ///only works if the size of all tiles is equal.
//   ///
//   void goToSelectedItem(ValueItem<T> item) {
//     final index = listaFiltrada.indexOf(item);
//     if (index > 1) {
//       scrollController.scrollTo(
//         index: index,
//         duration: overlayListSettings.reOpenedScrollDuration,
//         curve: Curves.ease,
//       );
//     }
//   }

//   void itemAdded(String text) {
//     final item = newValueItem!(text);
//     onAddItem(item);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final PageStorageBucket pageStorageBucket = PageStorageBucket();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (selectedItem != null && shouldScroll) {
//         goToSelectedItem(selectedItem!);
//         updateShouldScroll();
//       }
//     });
//     return Card(
//       surfaceTintColor:
//           overlayListSettings.dialogBackgroundColor ?? backgroundColor,
//       color: overlayListSettings.dialogBackgroundColor ?? backgroundColor,
//       elevation: elevation,
//       child: AnimatedContainer(
//         duration: overlayListSettings.animationDuration,
//         height: overlayListSettings.dialogHeight,
//         width: dropdownwidth,
//         child: PageStorage(
//           bucket: pageStorageBucket,
//           child: ScrollablePositionedList.separated(
//             itemScrollController: scrollController,
//             padding: EdgeInsets.zero,
//             itemCount: listaFiltrada.length + (addMode ? 1 : 0),
//             separatorBuilder: (context, index) => SizedBox(
//               height: overlayListSettings.separatorHeight,
//             ),
//             itemBuilder: (context, index) {
//               if (index == listaFiltrada.length && addMode) {
//                 if (searchbarText != '') {
//                   final list = listaFiltrada
//                       .where(
//                         (element) =>
//                             element.label.latinize().toLowerCase().contains(
//                                   searchbarText.latinize().toLowerCase(),
//                                 ),
//                       )
//                       .toList();
//                   if (list.isEmpty) {
//                     return DefaultAddListItem(
//                       itemAdded: itemAdded,
//                       overlayListSettings: overlayListSettings,
//                       text: searchbarText,
//                       addAditionalWidget: addAditionalWidget,
//                     );
//                   }
//                 }
//                 return const SizedBox.shrink();
//               } else {
//                 return DefaultListTile<T>(
//                   deleteMode: deleteMode,
//                   editMode: editMode,
//                   item: listaFiltrada[index],
//                   onDelete: onDelete,
//                   onEdit: onEdit,
//                   onPressed: onPressed,
//                   overlayListSettings: overlayListSettings,
//                   selected: searchbarText == listaFiltrada[index].label,
//                   defaultAditionalWidget: defaultAditionalWidget,
//                 );
//               }
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
