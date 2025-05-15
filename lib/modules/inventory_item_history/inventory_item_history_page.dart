import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import './inventory_item_history_controller.dart';

class InventoryItemHistoryPage extends GetView<InventoryItemHistoryController> {
    
    const InventoryItemHistoryPage({super.key});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
              title: const Text('Item', style: TextStyle(color: Colors.white),),
              centerTitle: true,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              backgroundColor: context.themeDark,
              ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: context.themeGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              onPressed: () {},
              child: const Icon(Icons.add, color: Colors.white, size: 42),
              ),
            body: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: context.themeGray,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      iconColor: Colors.white70,
                      textColor: Colors.white70,
                      leading: Icon(Icons.build_sharp),
                      trailing: Icon(Icons.list_alt_outlined),
                      title: Text(controller.item.value.description, textAlign: TextAlign.center,),
                      subtitle: Text(
                        '${controller.item.value.quantity} ${controller.item.value.unit}', 
                        textAlign: TextAlign.center
                        ),
                    ),
                  ),
                ],
              ),
            ),
        );
    }
}