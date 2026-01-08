import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_info.dart';
import 'scaler.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${UserInfo.baseUrl}/get_my_recipes.php?user_id=${UserInfo.userId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _recipes = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        debugPrint("Fetch recipes failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching recipes: $e");
    }
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome ${UserInfo.username}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRecipes,
            tooltip: "Refresh",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            tooltip: "Logout",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? const Center(child: Text("No recipes yet. Tap + to add one."))
              : ListView.builder(
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _recipes[index];
                    final recipeId = _toInt(recipe['id']);
                    final recipeName = recipe['name']?.toString() ?? "";
                    final origServ = _toInt(recipe['original_servings']);

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(
                          recipeName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Serves: ${origServ ?? "-"}"),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          if (recipeId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Recipe ID missing, cannot open.")),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScalerPage(
                                recipeId: recipeId,
                                initialName: recipeName,
                                initialOriginalServings: origServ,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, '/scaler').then((_) => _fetchRecipes());
        },
      ),
    );
  }
}
