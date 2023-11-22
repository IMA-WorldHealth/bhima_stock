import 'dart:core';
import 'package:flutter/material.dart';

class SearchBhima extends StatelessWidget {
  SearchBhima(
      {super.key,
      required this.onSearch,
      this.name,
      this.hintText = 'Recherche ...',
      required this.searchController});

  final void Function(String val)? onSearch;
  final String? name;
  final String? hintText;
  final TextEditingController? searchController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: TextField(
        controller: searchController,
        onChanged: onSearch,
        decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.clear,
                color: Colors.black,
              ),
              onPressed: () => searchController?.clear(),
            ),
            prefixIcon: IconButton(
              icon: const Icon(
                Icons.search,
                color: Colors.black,
              ),
              onPressed: () {
                // Perform the search here
              },
            ),
            border: const OutlineInputBorder()),
      ),
    );
  }
}
