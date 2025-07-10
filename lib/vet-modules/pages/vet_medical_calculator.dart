import 'dart:math' show pow;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petpal/utils/colors.dart';

class MedicalCalculator extends StatefulWidget {
  const MedicalCalculator({super.key});

  @override
  State<MedicalCalculator> createState() => _MedicalCalculatorState();
}

class _MedicalCalculatorState extends State<MedicalCalculator> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _dosageController = TextEditingController();
  final _concentrationController = TextEditingController();
  final _fluidRateController = TextEditingController();
  final _durationController = TextEditingController();

  double? bsaResult;
  double? bmiResult;
  double? dosageResult;
  double? fluidRateResult;
  double? weightConversionResult;

  int _activeTabIndex = 0;

  bool _useMetricWeight = true;
  bool _useMetricHeight = true;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _dosageController.dispose();
    _concentrationController.dispose();
    _fluidRateController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _calculateBSA() {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      _showValidationError('Please enter the weight');
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      _showValidationError('Please enter a valid weight');
      return;
    }

    final weightInKg = _useMetricWeight ? weight : weight * 0.45359237;

    final bsa = 0.101 * pow(weightInKg, 2 / 3);
    setState(() {
      bsaResult = bsa;
    });
  }

  void _calculateBMI() {
    final weightText = _weightController.text.trim();
    final heightText = _heightController.text.trim();

    if (weightText.isEmpty || heightText.isEmpty) {
      _showValidationError('Please enter both weight and height');
      return;
    }

    final weight = double.tryParse(weightText);
    final height = double.tryParse(heightText);

    if (weight == null || weight <= 0 || height == null || height <= 0) {
      _showValidationError('Please enter valid values');
      return;
    }

    final weightInKg = _useMetricWeight ? weight : weight * 0.45359237;
    final heightInM = _useMetricHeight ? height / 100 : height * 0.0254;

    final bmi = weightInKg / (heightInM * heightInM);
    setState(() {
      bmiResult = bmi;
    });
  }

  void _calculateDosage() {
    final weightText = _weightController.text.trim();
    final dosageText = _dosageController.text.trim();
    final concentrationText = _concentrationController.text.trim();

    if (weightText.isEmpty || dosageText.isEmpty || concentrationText.isEmpty) {
      _showValidationError('Please fill all required fields');
      return;
    }

    final weight = double.tryParse(weightText);
    final dosage = double.tryParse(dosageText);
    final concentration = double.tryParse(concentrationText);

    if (weight == null ||
        weight <= 0 ||
        dosage == null ||
        dosage <= 0 ||
        concentration == null ||
        concentration <= 0) {
      _showValidationError('Please enter valid values');
      return;
    }

    final weightInKg = _useMetricWeight ? weight : weight * 0.45359237;

    final totalDose = (weightInKg * dosage) / concentration;
    setState(() {
      dosageResult = totalDose;
    });
  }

  void _calculateFluidRate() {
    final weightText = _weightController.text.trim();

    if (weightText.isEmpty) {
      _showValidationError('Please enter the weight');
      return;
    }

    final weight = double.tryParse(weightText);

    if (weight == null || weight <= 0) {
      _showValidationError('Please enter a valid weight');
      return;
    }

    final weightInKg = _useMetricWeight ? weight : weight * 0.45359237;

    final rate = (30 * weightInKg + 70) / 24;
    setState(() {
      fluidRateResult = rate;
    });
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearCalculator() {
    setState(() {
      switch (_activeTabIndex) {
        case 0:
          _weightController.clear();
          bsaResult = null;
          break;
        case 1:
          _weightController.clear();
          _heightController.clear();
          bmiResult = null;
          break;
        case 2:
          _weightController.clear();
          _dosageController.clear();
          _concentrationController.clear();
          dosageResult = null;
          break;
        case 3:
          _weightController.clear();
          _durationController.clear();
          fluidRateResult = null;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      appBar: AppBar(
        title: const Text(
          'Veterinary Calculator',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 44, 59, 70),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildCalculatorTabs(),
          Expanded(
            child: IndexedStack(
              index: _activeTabIndex,
              children: [
                _buildBSACalculator(),
                _buildBMICalculator(),
                _buildDosageCalculator(),
                _buildFluidRateCalculator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorTabs() {
    return Container(
      color: const Color.fromARGB(255, 44, 54, 60),
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabButton(0, 'BSA', Icons.pets),
            _buildTabButton(1, 'BMI', Icons.monitor_weight),
            _buildTabButton(2, 'Drug Dosage', Icons.medication),
            _buildTabButton(3, 'Fluid Rate', Icons.water_drop),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isActive = _activeTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBSACalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: const Color.fromARGB(255, 44, 54, 60),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'Body Surface Area',
                'Calculate the BSA of the pet for accurate drug dosing',
                Icons.pets,
              ),
              const SizedBox(height: 24),
              _buildWeightInput(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _calculateBSA,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Calculate BSA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _clearCalculator,
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    tooltip: 'Clear',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (bsaResult != null)
                _buildResultDisplay(
                  'Body Surface Area',
                  '${bsaResult!.toStringAsFixed(3)} m²',
                  _getBSAInterpretation(bsaResult!),
                ),
              const SizedBox(height: 16),
              _buildInfoSection(
                'Why is BSA important?',
                'BSA is often used to calculate drug doses more accurately than body weight, '
                    'particularly for drugs with a narrow therapeutic index or significant toxicity.',
              ),
              const SizedBox(height: 16),
              _buildInfoSection(
                'Formula',
                'BSA (m²) = 0.101 × (weight in kg)^(2/3)',
                isFormula: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBMICalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: const Color.fromARGB(255, 44, 54, 60),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'Body Mass Index',
                'Assess body condition and nutritional status',
                Icons.monitor_weight,
              ),
              const SizedBox(height: 24),
              _buildWeightInput(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      'Height',
                      _heightController,
                      'Enter height',
                      'height',
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildUnitToggle(
                    _useMetricHeight,
                    'cm',
                    'in',
                    (value) => setState(() => _useMetricHeight = value),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _calculateBMI,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Calculate BMI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _clearCalculator,
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    tooltip: 'Clear',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (bmiResult != null)
                _buildResultDisplay(
                  'Body Mass Index',
                  '${bmiResult!.toStringAsFixed(2)}',
                  _getBMIInterpretation(bmiResult!),
                ),
              const SizedBox(height: 16),
              _buildInfoSection(
                'Formula',
                'BMI = weight(kg) / (height(m))²',
                isFormula: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDosageCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: const Color.fromARGB(255, 44, 54, 60),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'Drug Dosage',
                'Calculate accurate medication doses',
                Icons.medication,
              ),
              const SizedBox(height: 24),
              _buildWeightInput(),
              const SizedBox(height: 16),
              _buildInputField(
                'Dosage',
                _dosageController,
                'Enter mg per kg',
                'mg/kg',
              ),
              const SizedBox(height: 16),
              _buildInputField(
                'Concentration',
                _concentrationController,
                'Enter medication concentration',
                'mg/ml',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _calculateDosage,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Calculate Dosage'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _clearCalculator,
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    tooltip: 'Clear',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (dosageResult != null)
                _buildResultDisplay(
                  'Required Medication',
                  '${dosageResult!.toStringAsFixed(2)} ml',
                  _getDosageDescription(dosageResult!),
                ),
              const SizedBox(height: 16),
              _buildInfoSection(
                'Formula',
                'Total dose (ml) = (weight × dosage) / concentration',
                isFormula: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFluidRateCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: const Color.fromARGB(255, 44, 54, 60),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'Fluid Rate',
                'Calculate maintenance fluid requirements',
                Icons.water_drop,
              ),
              const SizedBox(height: 24),
              _buildWeightInput(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _calculateFluidRate,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Calculate Fluid Rate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _clearCalculator,
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    tooltip: 'Clear',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (fluidRateResult != null) ...[
                _buildResultDisplay(
                  'Maintenance Fluid Rate',
                  '${fluidRateResult!.toStringAsFixed(2)} ml/hr',
                  'Standard maintenance rate',
                ),
                const SizedBox(height: 8),
                _buildResultDisplay(
                  'Daily Fluid Requirement',
                  '${(fluidRateResult! * 24).toStringAsFixed(2)} ml/day',
                  'Total 24-hour requirement',
                ),
              ],
              const SizedBox(height: 16),
              _buildInfoSection(
                'Formula',
                'Fluid rate (ml/hr) = (30 × weight(kg) + 70) / 24',
                isFormula: true,
              ),
              const SizedBox(height: 16),
              _buildInfoSection(
                'Important Note',
                'This is a basic maintenance calculation. Adjust as needed based on the patient\'s condition, '
                    'including dehydration status, ongoing losses, and underlying disease.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String description, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildWeightInput() {
    return Row(
      children: [
        Expanded(
          child: _buildInputField(
            'Weight',
            _weightController,
            'Enter pet\'s weight',
            'weight',
          ),
        ),
        const SizedBox(width: 8),
        _buildUnitToggle(
          _useMetricWeight,
          'kg',
          'lb',
          (value) => setState(() => _useMetricWeight = value),
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint,
    String suffixText,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        suffixText: suffixText.isNotEmpty ? suffixText : null,
        suffixStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color.fromARGB(255, 55, 65, 70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.secondary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
    );
  }

  Widget _buildUnitToggle(
    bool isFirst,
    String firstLabel,
    String secondLabel,
    Function(bool) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 55, 65, 70),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        children: [
          _buildUnitOption(isFirst, firstLabel, () => onChanged(true)),
          _buildUnitOption(!isFirst, secondLabel, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _buildUnitOption(bool isSelected, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResultDisplay(String label, String value, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    String content, {
    bool isFormula = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFormula ? Icons.functions : Icons.info_outline,
                size: 16,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: isFormula ? AppColors.primary : Colors.white70,
              fontSize: 13,
              fontStyle: isFormula ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _getBSAInterpretation(double bsa) {
    if (bsa < 0.1) return 'Very small animal';
    if (bsa < 0.25) return 'Small animal';
    if (bsa < 0.5) return 'Medium-small animal';
    if (bsa < 1.0) return 'Medium animal';
    return 'Large animal';
  }

  String _getBMIInterpretation(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  String _getDosageDescription(double dosage) {
    if (dosage < 0.1) return 'Very small dose - confirm calculation';
    if (dosage > 10) return 'Large dose - double-check calculation';
    return 'Standard therapeutic dose';
  }
}
