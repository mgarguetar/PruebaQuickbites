import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePageKitchen extends StatefulWidget {
  @override
  _HomePageKitchenState createState() => _HomePageKitchenState();
}

class _HomePageKitchenState extends State<HomePageKitchen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cocina', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: [
            Tab(text: 'Pendientes'),
            Tab(text: 'Listos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pendientes Tab
          _buildOrdersList('pending'),
          // Listos Tab
          _buildOrdersList('ready'),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String statusFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('kitchen_orders')
          .where('status', isEqualTo: statusFilter)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No hay órdenes ${statusFilter == 'pending' ? 'pendientes' : 'listas'}.'));
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            final List<dynamic> items = order['items'] ?? [];
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map((item) {
                  final Map<String, dynamic> foodItem = item as Map<String, dynamic>;
                  
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  foodItem['nombre'] ?? 'Sin nombre',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (statusFilter == 'pending')
                                SizedBox(
                                  height: 40,
                                  width: 40,
                                  child: Container(
                                    color: Colors.grey[300],
                                    child: IconButton(
                                      icon: Icon(Icons.check, size: 20),
                                      onPressed: () {
                                        FirebaseFirestore.instance
                                            .collection('kitchen_orders')
                                            .doc(orders[index].id)
                                            .update({'status': 'ready'});
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Mesa: ${order['mesaNumber'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            );
          },
        );
      },
    );
  }
}