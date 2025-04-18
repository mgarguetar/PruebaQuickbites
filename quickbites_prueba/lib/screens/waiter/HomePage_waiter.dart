import 'package:flutter/material.dart';
import 'package:quickbites_prueba/firebase_service.dart';
import 'package:quickbites_prueba/screens/waiter/SeleccionMesaScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:quickbites_prueba/screens/waiter/menu_waiter.dart';

class HomePageWaiter extends StatelessWidget {
  const HomePageWaiter({Key? key}) : super(key: key);

  // Función para obtener todas las mesas ocupadas actualmente
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesero'),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
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
                Expanded(
                  child: occupiedTables.isEmpty
                      ? const Center(child: Text('No hay mesas ocupadas en este momento.'))
                      : ListView.builder(
                          itemCount: occupiedTables.length,
                          itemBuilder: (context, index) {
                            final table = occupiedTables[index];
                            final String tableNumber = table['number'].toString();
                            final Timestamp? startTime = table['occupiedSince'] as Timestamp?;
                            final String startTimeFormatted = startTime != null
                                ? DateFormat.jm().format(startTime.toDate())
                                : 'N/A';
                                
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
                                  child: Text(tableNumber),
                                ),
                                title: Text(
                                  'Mesa No. $tableNumber',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ocupada desde: $startTimeFormatted'),
                                    if (table['currentOrder'] != null)
                                      Text('Orden en progreso: Sí'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'OCUPADA',
                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_ios, size: 16),
                                  ],
                                ),
                                onTap: () {
                                  // Navegar a la pantalla de menú al tocar la mesa ocupada
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MenuScreen(
                                        mesaId: table['id'],
                                        mesaNumber: tableNumber,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                // Botón para seleccionar mesa nueva
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeleccionMesaScreen(
                            onMesaSeleccionada: (mesaId, mesaNumber) {
                              // Primero, actualizar el estado de la mesa a "occupied"
                              FirebaseFirestore.instance.collection('tables').doc(mesaId).update({
                                'status': 'occupied',
                                'occupiedSince': FieldValue.serverTimestamp(),
                              }).then((_) {
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
                              });
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
              ],
            ),
          );
        },
      ),
    );
  }
}