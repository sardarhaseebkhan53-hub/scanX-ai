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
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: availableTags.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = selectedTag == null;
                return ChoiceChip(
                  label: const Text('All'),
                  selected: isSelected,
                  onSelected: (_) => onTagSelected(null),
                );
              }

              final tag = availableTags[index - 1];
              final isSelected = selectedTag == tag;

              return ChoiceChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (_) => onTagSelected(isSelected ? null : tag),
              );
            },
          ),
        ),
      ],
    );
  }
}
