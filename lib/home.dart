import 'package:flutter/material.dart';

// ingredient class
class Ingredient {
  String name;
  double qty;
  String unit;
  String meal;

  Ingredient({required this.name, required this.qty, required this.unit, required this.meal});

  double getScaledQty(double factor) {
    return qty * factor;
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController originalServings = TextEditingController();
  TextEditingController targetServings = TextEditingController();
  
  TextEditingController qtyController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  List<Ingredient> ingredients = [];
  String selectedUnit = '';
  String errorMsg = '';
  bool _isBreakfast = false;
  bool _isLunch= false;
  bool _isDinner= false;
  List<String> units = ['', 'g', 'kg', 'ml', 'L', 'C', 'tsp', 'tbsp', 'oz', 'lb'];

  double calculateScale() {
    var orig = double.tryParse(originalServings.text);
    var target = double.tryParse(targetServings.text);
    if (orig == null || target == null || orig == 0) {return 1.0;}
    return target / orig;
  }

  String _getSelectedMeal(){
    if (_isBreakfast) return 'Breakfast';
    if (_isLunch) return 'Lunch';
    if (_isDinner) return 'Dinner';
    return '';
    }

  void addIngredient() {
    var qty = double.tryParse(qtyController.text);
    var name = nameController.text.trim();
    final meal= _getSelectedMeal();
    if (qty == null || name.isEmpty) {
      setState(() {
        errorMsg = 'Please fill quantity and ingredient name';
      });
      return;
    }

    setState(() {
      ingredients.add(Ingredient(
        name: name, 
        qty: qty, 
        unit: selectedUnit,
        meal: meal,
      ));
      
      qtyController.clear();
      nameController.clear();
      selectedUnit = '';
      errorMsg = '';
      _isBreakfast = false;
      _isLunch = false;
      _isDinner = false;
    });
  }

  void clearEverything() {
    setState(() {
      originalServings.clear();
      targetServings.clear();
      ingredients.clear();
      qtyController.clear();
      nameController.clear();
      selectedUnit = '';
      errorMsg = '';
      _isBreakfast = false;
      _isLunch = false;
      _isDinner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double scaleFactor = calculateScale();

    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Scaler'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(14.0),
        child: Column(
          children: [
            // servings input row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: originalServings,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Original servings',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: targetServings,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Target servings',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // ingredient input row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedUnit,
                    items: units.map((u) {
                      return DropdownMenuItem<String>(
                        value: u,
                        child: Text(u.isEmpty ? '-' : u),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedUnit = val ?? '';
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded( 
                  flex: 4,
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Ingredient',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),
            
                        Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Breakfast'),
                    value: _isBreakfast,
                    onChanged: (val) {
                      setState(() {
                        _isBreakfast = val ?? false;
                        if (_isBreakfast) {
                          _isLunch = false;
                          _isDinner = false;
                        }
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Lunch'),
                    value: _isLunch,
                    onChanged: (val) {
                      setState(() {
                        _isLunch = val ?? false;
                        if (_isLunch) {
                          _isBreakfast = false;
                          _isDinner = false;
                        }
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Dinner'),
                    value: _isDinner,
                    onChanged: (val) {
                      setState(() {
                        _isDinner = val ?? false;
                        if (_isDinner) {
                          _isBreakfast = false;
                          _isLunch = false;
                        }
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: addIngredient,
                    child: Text('Add Ingredient'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: clearEverything,
                    child: Text('Clear All'),
                  ),
                ),
              ],
            ),

            if (errorMsg.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  errorMsg,
                  style: TextStyle(color: Colors.red),
                ),
              ),

            SizedBox(height: 10),

            // list of ingredients
            Expanded(
              child: ingredients.isEmpty
                  ? Center(
                      child: Text('No ingredients yet'))
                  : ListView.builder(
                      itemCount: ingredients.length,
                      itemBuilder: (context, index) {
                        Ingredient ing = ingredients[index];
                        double scaledAmount = ing.getScaledQty(scaleFactor);
                        
                        String unitDisplay = ing.unit.isEmpty ? '' : ' ${ing.unit}';

                        return Card(
                          child: ListTile(
                            title: Text('${ing.qty}$unitDisplay ${ing.name}'),
                            subtitle: Text('Meal: ${ing.meal}, ''Scaled: ${scaledAmount.toStringAsFixed(2)}$unitDisplay'),
                            
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