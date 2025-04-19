import 'package:flutter/material.dart';
import 'package:quickbites_prueba/firebase_service.dart';
import 'package:quickbites_prueba/screens/waiter/SeleccionMesaScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:quickbites_prueba/screens/waiter/menu_waiter.dart';

class HomePageWaiter extends StatelessWidget {
  const HomePageWaiter({Key? key}) : super(key: key);

  // Stream para obtener mesas ocupadas
  Stream<List<Map<String, dynamic>>> getOccupiedTablesStream() {
    return FirebaseFirestore.instance
        .collection('tables')
        .where('status', isEqualTo: 'occupied')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Stream para obtener órdenes listas de cocina
  Stream<List<Map<String, dynamic>>> getReadyOrdersStream() {
    return FirebaseFirestore.instance
        .collection('kitchen_orders')
        .where('status', isEqualTo: 'ready')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
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
      body: Column(
        children: [
          // Sección de mesas ocupadas
          Expanded(
            flex: 2,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getOccupiedTablesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final occupiedTables = snapshot.data ?? [];
                
                // Ordenar las mesas por número
                occupiedTables.sort((a, b) => (a['number'] as num).compareTo(b['number'] as num));

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado de mesas ocupadas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mesas Ocupadas',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total: ${occupiedTables.length} mesas',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Lista de mesas ocupadas
                      Expanded(
                        child: occupiedTables.isEmpty
                            ? const Center(child: Text('No hay mesas ocupadas actualmente.'))
                            : ListView.builder(
                                itemCount: occupiedTables.length,
                                itemBuilder: (context, index) {
                                  final table = occupiedTables[index];
                                  // Obtener la hora desde timestamp si existe
                                  String horaOcupada = "Ocupada";
                                  if (table['occupiedAt'] != null) {
                                    final Timestamp occupiedTime = table['occupiedAt'];
                                    horaOcupada = "Ocupada desde: ${DateFormat.jm().format(occupiedTime.toDate())}";
                                  }
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: Colors.orange.shade200, width: 1),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        // Navegar a la pantalla de menú
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MenuScreen(
                                              mesaId: table['id'],
                                              mesaNumber: table['number'].toString(),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            // Círculo con número de mesa
                                            CircleAvatar(
                                              radius: 25,
                                              backgroundColor: Colors.orange,
                                              child: Text(
                                                table['number'].toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Información de la mesa
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Mesa No. ${table['number'].toString()}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    horaOcupada,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Etiqueta de OCUPADA y flecha
                                            Column(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red[100],
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: const Text(
                                                    'OCUPADA',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Sección de órdenes listas de cocina
          Expanded(
            flex: 1,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getReadyOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final readyOrders = snapshot.data ?? [];
                
                // Ordenar las órdenes por número de mesa
                readyOrders.sort((a, b) => (a['mesaNumber'].toString().compareTo(b['mesaNumber'].toString())));

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Órdenes Listas',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total: ${readyOrders.length} órdenes',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Lista de órdenes listas
                      Expanded(
                        child: readyOrders.isEmpty
                            ? const Center(child: Text('No hay órdenes listas actualmente.'))
                            : ListView.builder(
                                itemCount: readyOrders.length,
                                itemBuilder: (context, index) {
                                  final order = readyOrders[index];
                                  final items = order['items'] as List<dynamic>? ?? [];
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: Colors.green.shade200, width: 1),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          // Círculo con número de mesa
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Colors.green,
                                            child: Text(
                                              order['mesaNumber']?.toString() ?? '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Información de los ítems
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                ...items.take(2).map((item) {
                                                  return Text(
                                                    '${item['cantidad'] ?? 1}x ${item['nombre'] ?? 'Producto'}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  );
                                                }).toList(),
                                                if (items.length > 2)
                                                  Text(
                                                    '...y ${items.length - 2} más',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          // Botón para marcar como entregado
                                          ElevatedButton(
                                            onPressed: () {
                                              // Marcar orden como entregada/completada
                                              FirebaseFirestore.instance
                                                  .collection('kitchen_orders')
                                                  .doc(order['id'])
                                                  .update({'status': 'delivered'});
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              'ENTREGAR',
                                              style: TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Botón para seleccionar nueva mesa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SeleccionMesaScreen(
                        onMesaSeleccionada: (mesaId, mesaNumber) {
                          Navigator.pop(context);

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
                  'SELECCIONAR MESA NUEVA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}