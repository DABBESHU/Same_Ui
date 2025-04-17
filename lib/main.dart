import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(FreightApp());

class FreightApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: FreightForm());
  }
}

class FreightForm extends StatefulWidget {
  @override
  _FreightFormState createState() => _FreightFormState();
}

class _FreightFormState extends State<FreightForm> {
  // Controllers
  final originController = TextEditingController();
  final destinationController = TextEditingController();
  final commodityController = TextEditingController();
  final numberOfBoxesController = TextEditingController();
  final weightController = TextEditingController();
  final _cutOffDateController = TextEditingController();

  // State variables
  bool isFCL = true;
  bool isLCL = false;
  bool includeOriginNearby = false;
  bool includeDestinationNearby = false;
  String containerSize = "40' Standard";

  // Auto-complete variables
  List<String> originSuggestions = [];
  List<String> destinationSuggestions = [];
  bool isOriginLoading = false;
  bool isDestinationLoading = false;

  @override
  void initState() {
    super.initState();
    originController.addListener(_onOriginChanged);
    destinationController.addListener(_onDestinationChanged);
  }

  @override
  void dispose() {
    originController.dispose();
    destinationController.dispose();
    commodityController.dispose();
    numberOfBoxesController.dispose();
    weightController.dispose();
    _cutOffDateController.dispose();
    super.dispose();
  }

  Future<void> _onOriginChanged() async {
    if (originController.text.isEmpty) {
      setState(() => originSuggestions = []);
      return;
    }
    setState(() => isOriginLoading = true);
    final suggestions = await _fetchSuggestions(originController.text);
    setState(() {
      originSuggestions = suggestions;
      isOriginLoading = false;
    });
  }

  Future<void> _onDestinationChanged() async {
    if (destinationController.text.isEmpty) {
      setState(() => destinationSuggestions = []);
      return;
    }
    setState(() => isDestinationLoading = true);
    final suggestions = await _fetchSuggestions(destinationController.text);
    setState(() {
      destinationSuggestions = suggestions;
      isDestinationLoading = false;
    });
  }

  Future<List<String>> _fetchSuggestions(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http
          .get(
            Uri.parse('http://universities.hipolabs.com/search?name=$query'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map<String>((univ) => univ['name'].toString()).toList();
      }
      return _getFallbackSuggestions(query);
    } catch (e) {
      print('Error fetching suggestions: $e');
      return _getFallbackSuggestions(query);
    }
  }

  List<String> _getFallbackSuggestions(String query) {
    return [
          'Middlebury College',
          'American University of Middle East',
          'Middlesex Community College',
          'Middlesex County College',
          'Middlesex University - London',
          'Middlesbrough College',
          'Middle East Technical University',
          'Middle East University',
          'Middle Tennessee State University',
          'Middle Georgia State College',
        ]
        .where((name) => name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F4FB),
        title: const Padding(
          padding: EdgeInsets.only(top: 1.0),
          child: Text(
            'Search the best Freight Rates',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2C4EFF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {},
              child: const Text(
                'History',
                style: TextStyle(color: Color(0xFF2C4EFF)),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOriginDestinationRow(),
                const SizedBox(height: 10),
                _buildCommodityDateRow(),
                const SizedBox(height: 10),
                _buildShipmentTypeSelection(),
                const SizedBox(height: 10),
                _buildContainerFields(),
                const SizedBox(height: 5),
                _buildInfoText(),
                const SizedBox(height: 20),
                _buildContainerDimensions(),
                const SizedBox(height: 30),
                _buildSearchButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOriginDestinationRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 25.0),
      child: Row(
        children: [
          Expanded(
            child: _buildAutoCompleteField(
              'Origin',
              originController,
              originSuggestions,
              isOriginLoading,
              Icons.place_outlined,
              'Include nearby origin ports',
              includeOriginNearby,
              (value) => setState(() => includeOriginNearby = value!),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildAutoCompleteField(
              'Destination',
              destinationController,
              destinationSuggestions,
              isDestinationLoading,
              Icons.place_outlined,
              'Include nearby destination ports',
              includeDestinationNearby,
              (value) => setState(() => includeDestinationNearby = value!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoCompleteField(
    String hint,
    TextEditingController controller,
    List<String> suggestions,
    bool isLoading,
    IconData icon,
    String checkboxLabel,
    bool checkboxValue,
    Function(bool?) onCheckboxChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return suggestions.where(
              (option) => option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            );
          },
          onSelected: (String selection) {
            controller.text = selection;
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: Icon(icon, color: Colors.grey),
                suffixIcon:
                    isLoading
                        ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(15),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            children: [
              RoundedCheckbox(
                value: checkboxValue,
                onChanged: onCheckboxChanged,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  checkboxLabel,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommodityDateRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: 'Commodity',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'item1', child: Text('Item 1')),
            ],
            onChanged: (_) {},
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _cutOffDateController,
            decoration: InputDecoration(
              hintText: 'Cut Off Date',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            readOnly: true,
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                _cutOffDateController.text = DateFormat(
                  'yyyy-MM-dd',
                ).format(pickedDate);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShipmentTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Shipment Type:'),
        Padding(
          padding: const EdgeInsets.only(top: 15, right: 15, bottom: 15),
          child: Row(
            children: [
              RoundedCheckbox(
                value: isFCL,
                onChanged: (val) => setState(() => isFCL = val!),
              ),
              const SizedBox(width: 5),
              const Text('FCL'),
              const SizedBox(width: 50),
              RoundedCheckbox(
                value: isLCL,
                onChanged: (val) => setState(() => isLCL = val!),
              ),
              const SizedBox(width: 5),
              const Text('LCL'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContainerFields() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: containerSize,
            decoration: InputDecoration(
              labelText: 'Container Size',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(15),
            ),
            items:
                ["40' Standard", "20' Standard", "45' High Cube"]
                    .map(
                      (size) =>
                          DropdownMenuItem(value: size, child: Text(size)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => containerSize = value!),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: numberOfBoxesController,
            decoration: InputDecoration(
              hintText: 'No of Boxes',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(15),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: weightController,
            decoration: InputDecoration(
              hintText: 'Weight (Kg)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(15),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoText() {
    return const Text(
      'To obtain accurate rate for spot rate with guaranteed space and booking, '
      'please ensure your container count and weight per container is accurate.',
      style: TextStyle(fontSize: 12, color: Colors.grey),
    );
  }

  Widget _buildContainerDimensions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Container Internal Dimensions:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        const Text('Length: 39.46 ft'),
        const Text('Width: 7.70 ft'),
        const Text('Height: 7.84 ft'),
      ],
    );
  }

  Widget _buildSearchButton() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF2C4EFF)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () {},
          icon: const Icon(Icons.search, color: Color(0xFF2C4EFF)),
          label: const Text(
            'Search',
            style: TextStyle(color: Color(0xFF2C4EFF)),
          ),
        ),
      ),
    );
  }
}

class RoundedCheckbox extends StatelessWidget {
  final bool value;
  final Function(bool?)? onChanged;

  const RoundedCheckbox({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged?.call(!value),
      child: Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5),
          color: value ? const Color(0xFF2C4EFF) : Colors.white,
        ),
        child:
            value
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
      ),
    );
  }
}
