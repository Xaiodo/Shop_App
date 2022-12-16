import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/screens/products_overview_screen.dart';

import '../providers/orders.dart' show Orders;
import '../widgets/order_item.dart';
import '../widgets/app_drawer.dart';

class OrdersScreen extends StatelessWidget {
  static const routeName = '/orders';

  const OrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder(
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 100,
                  ),
                  const Text(
                    'You don`t have any orders yet, please go to shop and make one',
                  ),
                  const SizedBox(
                    height: 100,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed(
                            ProductOverviewScreen.routeName);
                      },
                      child: const Text('Shop'))
                ],
              ),
            );
          }
          if (snapshot.error != null) {
            return Center(
              child: Text(
                'An error occurred: ${snapshot.error.toString()} ',
              ),
            );
          }

          return Consumer<Orders>(
            builder: ((context, orderData, child) => ListView.builder(
                  itemBuilder: (ctx, i) =>
                      OrderItem(order: orderData.orders[i]),
                  itemCount: orderData.orders.length,
                )),
          );
        },
        future: Provider.of<Orders>(context, listen: false).fetchAndSetOrders(),
      ),
    );
  }
}
