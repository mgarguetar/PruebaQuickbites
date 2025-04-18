import 'package:flutter/material.dart';
import 'package:quickbites_prueba/firebase_service.dart';
import 'package:quickbites_prueba/screens/waiter/SeleccionMesaScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:quickbites_prueba/screens/waiter/menu_waiter.dart';

class HomePageWaiter extends StatelessWidget {
  const HomePageWaiter({Key? key}) : super(key: key);

  // Implementación directa de getOrdersStream para asegurar que obtenemos todas las órdenes activas
  Stream<List<Map<String, dynamic>>> getOrdersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'active') // Asumiendo que las órdenes activas tienen este estado
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Incluir el ID del documento
            return data;
          }).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesero'),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];
          
          // Ordenar las órdenes por número de mesa para mejor visualización
          orders.sort((a, b) => (a['mesa'] as num).compareTo(b['mesa'] as num));

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tus Órdenes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total: ${orders.length} mesas',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: orders.isEmpty
                      ? const Center(child: Text('No hay órdenes disponibles.'))
                      : ListView.builder(
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            final Timestamp createdAt = order['createdAt'] ?? Timestamp.now();
                            final String horaFormateada = DateFormat.jm().format(createdAt.toDate());
                            
                            // Obtener el total formateado como moneda
                            final double total = order['total'] is num ? (order['total'] as num).toDouble() : 0.0;
                            final String totalFormateado = NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(total);
                            
                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.orange.shade200),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange,
                                  child: Text(order['mesa'].toString()),
                                ),
                                title: Text(
                                  'Mesa No. ${order['mesa'].toString()}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Inicio: $horaFormateada'),
                                    if (order['items'] != null)
                                      Text('Items: ${(order['items'] as List).length}'),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      totalFormateado,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Activa',
                                            style: TextStyle(color: Colors.green, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // Navegar a la pantalla de menú al tocar la orden
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MenuScreen(
                                        mesaId: order['tableId'] ?? '',
                                        mesaNumber: order['mesa'].toString(),
                                      ),
                                    ),
                                  );
                                },
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                // Botón para seleccionar mesa
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeleccionMesaScreen(
                            onMesaSeleccionada: (mesaId, mesaNumber) {
                              Navigator.pop(context); // Cierra la pantalla de selección de mesa

                              // Ahora redirige al menú
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MenuScreen(
                                    mesaId: mesaId,
                                    mesaNumber: mesaNumber,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.table_restaurant, color: Colors.white),
                    label: const Text(
                      'SELECCIONAR MESA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}