import 'package:flutter/material.dart';
import 'package:petpal/utils/colors.dart';

class TextFieldWithUnitDropdown extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final List<String> units;
  final String initialUnit;
  final Function(String) onUnitChanged;
  final bool isRequired;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final IconData? prefixIcon;

  const TextFieldWithUnitDropdown({
    Key? key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.units,
    required this.initialUnit,
    required this.onUnitChanged,
    this.isRequired = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
  }) : super(key: key);

  @override
  State<TextFieldWithUnitDropdown> createState() =>
      _TextFieldWithUnitDropdownState();
}

class _TextFieldWithUnitDropdownState extends State<TextFieldWithUnitDropdown> {
  late String _selectedUnit;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.prefixIcon != null)
              Icon(widget.prefixIcon, size: 16, color: Colors.grey[400]),
            if (widget.prefixIcon != null) const SizedBox(width: 8),
            Text(
              widget.label + (widget.isRequired ? ' *' : ''),
              style: TextStyle(
                color: _isFocused ? AppColors.primary : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused ? AppColors.primary : Colors.grey[700]!,
              width: 1,
            ),
            boxShadow:
                _isFocused
                    ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: widget.keyboardType,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 55, 65, 70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(
                          16,
                          14,
                          85,
                          14,
                        ),
                      ),
                      validator: widget.validator,
                    ),
                  ),
                ],
              ),

              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 85,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 65, 75, 80),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(7),
                      bottomRight: Radius.circular(7),
                    ),
                    border: Border.all(color: Colors.transparent, width: 0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedUnit,
                      isDense: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: _isFocused ? AppColors.primary : Colors.white70,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedUnit = newValue;
                          });
                          widget.onUnitChanged(newValue);
                        }
                      },
                      items:
                          widget.units.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      _selectedUnit == value
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color.fromARGB(255, 50, 60, 65),
                      alignment: AlignmentDirectional.center,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
