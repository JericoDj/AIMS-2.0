import 'package:flutter/material.dart';

class ManageAccountsPage extends StatelessWidget {
  const ManageAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final users = [
      {
        "name": "Esquilador, Mhiel James",
        "role": "User",
        "image": "assets/JericoDeJesus.png",
      },
      {
        "name": "Saligumba, Arturo Enrique",
        "role": "User",
        "image": "assets/JericoDeJesus.png",
      },
      {
        "name": "Dionisio, Danielle",
        "role": "User",
        "image": "assets/JericoDeJesus.png",
      }
    ];

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // ------------------- PROFILE GREETING -------------------
          Column(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundImage: AssetImage( "assets/JericoDeJesus.png"),
              ),
              const SizedBox(height: 12),
              const Text(
                "Hi, Baby Jane!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Administrator",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),

          const SizedBox(height: 35),

          // ------------------- MAIN CARD -------------------
          Container(
            width: 700,
            decoration: BoxDecoration(
              color: const Color(0xFFD0E8B5),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Column(
              children: [
                // USER ROWS
                for (var index = 0; index < users.length; index++)
                  Column(
                    children: [
                      _UserRow(
                        image: users[index]["image"]!,
                        name: users[index]["name"]!,
                        role: users[index]["role"]!,
                        onEdit: () {},
                        onRemove: () {},
                      ),

                      // Divider line between rows, except last
                      if (index != users.length - 1)
                        Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.6),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                    ],
                  ),

                // CREATE ACCOUNT BUTTON
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 70,
                    alignment: Alignment.center,
                    child: Text(
                      "+ Create Account",
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.green[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//
// ==================== USER ROW WIDGET ====================
//
class _UserRow extends StatelessWidget {
  final String image;
  final String name;
  final String role;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _UserRow({
    required this.image,
    required this.name,
    required this.role,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // USER AVATAR
          CircleAvatar(
            radius: 26,
            backgroundImage: AssetImage(image),
          ),

          const SizedBox(width: 20),

          // NAME
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 20,
                color: Colors.green[900],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // ROLE
          Text(
            role,
            style: TextStyle(
              fontSize: 18,
              color: Colors.green[900],
            ),
          ),

          const SizedBox(width: 40),

          // EDIT
          GestureDetector(
            onTap: onEdit,
            child: Text(
              "Edit",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
          ),

          const SizedBox(width: 25),

          // REMOVE
          GestureDetector(
            onTap: onRemove,
            child: Text(
              "Remove",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
