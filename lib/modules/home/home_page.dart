import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import './home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        elevation: 0,
        backgroundColor: context.themeDark,
        title: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              FlutterLogo(size: 50),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem vindo de volta,',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 05),
                  Text(
                    controller.user.value?.name ?? "",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      endDrawer: Drawer(backgroundColor: context.themeGray),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              InkWell(
                onTap: () {},
                child: Container(
                  width: double.maxFinite,
                  height: 100,
                  padding: EdgeInsets.only(left: 10, right: 10),
                  decoration: BoxDecoration(
                    color: context.themeGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: CircleAvatar(
                          child: Text(
                            '7',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: context.themeLightGray,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Serviços agendados para hoje',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              InkWell(
                onTap: () => Get.toNamed('/client'),
                child: Container(
                  width: double.maxFinite,
                  height: 100,
                  padding: EdgeInsets.only(left: 10, right: 10),
                  decoration: BoxDecoration(
                    color: context.themeGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: CircleAvatar(
                          backgroundColor: context.themeLightGray,
                          child: Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        '35 Clientes',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              InkWell(
                onTap: () {},
                child: Container(
                  width: double.maxFinite,
                  height: 100,
                  padding: EdgeInsets.only(left: 10, right: 10),
                  decoration: BoxDecoration(
                    color: context.themeGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: CircleAvatar(
                          backgroundColor: context.themeLightGray,
                          child: Icon(
                            Icons.construction_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Estoque',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              InkWell(
                onTap: () {},
                child: Container(
                  width: double.maxFinite,
                  height: 100,
                  padding: EdgeInsets.only(left: 10, right: 10),
                  decoration: BoxDecoration(
                    color: context.themeGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: CircleAvatar(
                          backgroundColor: context.themeLightGray,
                          child: Icon(
                            Icons.people_outline_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Colaboradores',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              InkWell(
                onTap: () {},
                child: Container(
                  width: double.maxFinite,
                  height: 100,
                  padding: EdgeInsets.only(left: 10, right: 10),
                  decoration: BoxDecoration(
                    color: context.themeGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: CircleAvatar(
                          backgroundColor: context.themeLightGray,
                          child: Icon(
                            Icons.local_shipping_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Veículos',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
