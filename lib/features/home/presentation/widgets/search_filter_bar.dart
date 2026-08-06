import 'package:flutter/material.dart';

class SearchFilterBar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String? selectedTag;
  final ValueChanged<String?> onTagSelected;
  final List<String> availableTags;

  const SearchFilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedTag,
    required this.onTagSelected,
    this.availableTags = const ['Invoices', 'Receipts', 'ID Cards', 'Legal', 'Personal'],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by filename, OCR text, or tags...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => onSearchChanged(''),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: selectedTag == null,
                    onSelected: (_) => onTagSelected(null),
                  ),
                ),
                ...availableTags.map((tag) {
                  final isSelected = selectedTag == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (_) => onTagSelected(isSelected ? null : tag),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
