import 'package:flutter/material.dart';

/// TODO(ui): implemented by feature agent — placeholder stub.
class ServiceFormScreen extends StatelessWidget {
  const ServiceFormScreen({super.key, required this.shopId, this.serviceId});
  final String shopId;
  final String? serviceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('ServiceFormScreen')));
  }
}
