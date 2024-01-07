import 'dart:core';
import 'package:flutter/material.dart';

class SearchBhima extends StatelessWidget {
  const SearchBhima(
      {super.key,
      required this.onSearch,
      this.name,
      this.clear,
      this.hintText = 'Recherche ...',
      required this.searchController});

  final void Function(String val)? onSearch;
  final String? name;
  final String? hintText;
  final TextEditingController? searchController;
  final void Function()? clear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: TextField(
        controller: searchController,
        onChanged: onSearch,
        decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 13),
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.clear,
                color: Colors.black,
              ),
              onPressed: () => clear!(),
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
