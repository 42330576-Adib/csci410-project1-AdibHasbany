import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_info.dart';

class Ingredient {
  String name;
  double qty;
  String unit;
  String mealType;

  Ingredient({
    required this.name,
    required this.qty,
    required this.unit,
    this.mealType = 'Lunch',
  });

  double scaledQty(double factor) => qty * factor;

  Map<String, dynamic> toJson() => {
        'name': name,
        'qty': qty,
        'unit': unit,
        'meal': mealType,
      };
}

class ScalerPage extends StatefulWidget {
  final int? recipeId; // if provided, open existing recipe
  final String? initialName;
  final int? initialOriginalServings;

  const ScalerPage({
    super.key,
    this.recipeId,
    this.initialName,
    this.initialOriginalServings,
  });

  @override
  State<ScalerPage> createState() => _ScalerPageState();
}

class _ScalerPageState extends State<ScalerPage> {
  final _recipeNameCtrl = TextEditingController();
  final _origCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();

  final _qtyCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  final List<Ingredient> _ingredients = [];
  String _selectedUnit = '';
  String _message = '';

  bool _loadingExisting = false;

  static const List<String> units = ['', 'g', 'kg', 'ml', 'L', 'C', 'tsp', 'tbsp', 'oz', 'lb'];

  double get _scaleFactor {
    final orig = double.tryParse(_origCtrl.text);
    final target = double.tryParse(_targetCtrl.text);
    if (orig == null || target == null || orig == 0) return 1.0;
    return target / orig;
  }

  @override
  void initState() {
    super.initState();

    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _recipeNameCtrl.text = widget.initialName!;
    }
    if (widget.initialOriginalServings != null) {
      _origCtrl.text = widget.initialOriginalServings.toString();
    }

    if (widget.recipeId != null) {
      _loadRecipeDetails(widget.recipeId!);
    }
  }

  @override
  void dispose() {
    _recipeNameCtrl.dispose();
    _origCtrl.dispose();
    _targetCtrl.dispose();
    _qtyCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecipeDetails(int recipeId) async {
    setState(() => _loadingExisting = true);

    try {
      final url = Uri.parse('${UserInfo.baseUrl}/get_recipe_details.php?recipe_id=$recipeId');
      final res = await http.get(url);

      if (res.statusCode != 200) {
        setState(() => _loadingExisting = false);
        debugPrint("Load recipe failed: ${res.statusCode} ${res.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load recipe (${res.statusCode})")),
        );
        return;
      }

      final data = jsonDecode(res.body);

      if (data["status"] != "success") {
        setState(() => _loadingExisting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"]?.toString() ?? "Load error")),
        );
        return;
      }

      final recipe = data["recipe"];
      final ingList = (data["ingredients"] as List?) ?? [];

      setState(() {
        _recipeNameCtrl.text = (recipe["name"] ?? "").toString();
        _origCtrl.text = (recipe["original_servings"] ?? "").toString();

        _ingredients
          ..clear()
          ..addAll(
            ingList.map((i) {
              final qty = double.tryParse(i["quantity"].toString()) ?? 0.0;
              return Ingredient(
                name: (i["name"] ?? "").toString(),
                qty: qty,
                unit: (i["unit"] ?? "").toString(),
                mealType: (i["meal_type"] ?? "Lunch").toString(),
              );
            }),
          );

        _loadingExisting = false;
      });
    } catch (e) {
      setState(() => _loadingExisting = false);
      debugPrint("Load recipe exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading recipe: $e")),
      );
    }
  }

  void _addIngredient() {
    final qty = double.tryParse(_qtyCtrl.text);
    final name = _nameCtrl.text.trim();

    if (qty == null || name.isEmpty) {
      setState(() => _message = 'Invalid input');
      return;
    }

    setState(() {
      _ingredients.add(Ingredient(name: name, qty: qty, unit: _selectedUnit));
      _qtyCtrl.clear();
      _nameCtrl.clear();
      _message = '';
    });
  }

  Future<void> _saveRecipeToCloud() async {
    if (_recipeNameCtrl.text.isEmpty || _origCtrl.text.isEmpty || _ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill name, servings, and ingredients")),
      );
      return;
    }

    try {
      final body = {
        "user_id": UserInfo.userId,
        "name": _recipeNameCtrl.text,
        "original_servings": double.parse(_origCtrl.text),
        "ingredients": _ingredients.map((i) => i.toJson()).toList(),
      };

      final response = await http.post(
        Uri.parse('${UserInfo.baseUrl}/add_recipe.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message']?.toString() ?? "Saved")),
      );

      if (data['status'] == 'success') {
        Navigator.pop(context); // Back to dashboard
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final factor = _scaleFactor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Scaler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveRecipeToCloud,
            tooltip: "Save to Cloud",
          )
        ],
      ),
      body: _loadingExisting
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _recipeNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Recipe Name (e.g. Pancakes)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _origCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Original Servings'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _targetCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Target Servings'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Scaling Factor: ${factor.toStringAsFixed(2)}x',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Qty'),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit.isEmpty ? null : _selectedUnit,
                          items: units
                              .map((u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u.isEmpty ? 'None' : u),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedUnit = v ?? ''),
                          decoration: const InputDecoration(labelText: 'Unit'),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        flex: 4,
                        child: TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: 'Ingredient'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: _addIngredient,
                      ),
                    ],
                  ),
                  if (_message.isNotEmpty)
                    Text(_message, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 10),

                  Expanded(
                    child: _ingredients.isEmpty
                        ? const Center(child: Text('No ingredients yet'))
                        : ListView.builder(
                            itemCount: _ingredients.length,
                            itemBuilder: (context, i) {
                              final ing = _ingredients[i];
                              final scaled = ing.scaledQty(factor);
                              final unitText = ing.unit.isEmpty ? '' : ' ${ing.unit}';

                              return Card(
                                child: ListTile(
                                  title: Text('${ing.qty}$unitText ${ing.name}'),
                                  subtitle: Text('Scaled: ${scaled.toStringAsFixed(2)}$unitText'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => setState(() => _ingredients.removeAt(i)),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
