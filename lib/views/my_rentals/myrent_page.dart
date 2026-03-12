import 'package:flutter/material.dart';

import 'package:rentals/services/transaction_service.dart';
import 'package:rentals/models/transaction_model.dart';
import 'package:rentals/views/my_rentals/widgets/host_request_card.dart';
import 'package:rentals/views/my_rentals/widgets/myrent_header.dart';
import 'package:rentals/views/my_rentals/widgets/myrent_toggle_switch.dart';
import 'package:rentals/views/my_rentals/widgets/rent_transaction_card.dart';

class MyrentPage extends StatefulWidget {
  final bool initialHostMode;
  final String? initialTransactionId;

  const MyrentPage({
    super.key,
    this.initialHostMode = true,
    this.initialTransactionId,
  });

  @override
  State<MyrentPage> createState() => _MyrentPageState();
}

class _MyrentPageState extends State<MyrentPage> {
  late bool isHostMode;

  @override
  void initState() {
    super.initState();
    isHostMode = widget.initialHostMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF113F67),
      body: Column(
        children: [
          MyRentHeader(
            onBack: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  MyRentToggleSwitch(
                    isHostMode: isHostMode,
                    onChanged: (value) => setState(() => isHostMode = value),
                  ),
                  const SizedBox(height: 35),
                  Expanded(
                    child: isHostMode
                        ? _buildHostRequestsList()
                        : _buildRentedItemsList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRemainingTimeText(DateTime? endAt) {
    if (endAt == null) return '--d : --h : --m';
    final now = DateTime.now();
    if (endAt.isBefore(now)) return 'Ended';
    final diff = endAt.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;
    return '${days.toString().padLeft(2, '0')}d : ${hours.toString().padLeft(2, '0')}h : ${mins.toString().padLeft(2, '0')}m';
  }

  Widget _buildHostRequestsList() {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionService.getUserHosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF113F67)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No one has requested your items yet.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final transactions = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return _buildHostRequestCard(transactions[index]);
          },
        );
      },
    );
  }

  Widget _buildHostRequestCard(TransactionModel tx) {
    final bool isTarget =
        widget.initialTransactionId != null &&
        tx.id == widget.initialTransactionId;

    return HostRequestCard(
      transaction: tx,
      isTarget: isTarget,
      remainingTimeText: _getRemainingTimeText(tx.endAt),
      onReject: () async {
        try {
          await TransactionService.rejectRentalRequest(transactionId: tx.id);
        } catch (e) {
          debugPrint('Failed to reject: $e');
        }
      },
      onAccept: (selectedDays) async {
        try {
          await TransactionService.acceptRentalRequest(
            transactionId: tx.id,
            rentalDays: selectedDays,
          );
        } catch (e) {
          debugPrint('Failed to accept: $e');
        }
      },
    );
  }

  Widget _buildRentedItemsList() {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionService.getUserRents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF113F67)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "You have not requested or rented any items yet.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final transactions = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return _buildTransactionCard(transactions[index]);
          },
        );
      },
    );
  }

  Widget _buildTransactionCard(TransactionModel tx) {
    final bool isTarget =
        widget.initialTransactionId != null &&
        tx.id == widget.initialTransactionId;

    return RentTransactionCard(
      transaction: tx,
      isTarget: isTarget,
      remainingTimeText: _getRemainingTimeText(tx.endAt),
    );
  }
}
