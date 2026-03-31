import 'package:flutter/material.dart';
import 'package:rentals/widgets/deal_item_card.dart';

class CategoryDealCard extends StatelessWidget {
  const CategoryDealCard({super.key, required this.deal, required this.onTap});

  final Map<String, dynamic> deal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DealItemCard(deal: deal, onTap: onTap);
  }
}
