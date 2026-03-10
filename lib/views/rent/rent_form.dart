import 'package:flutter/material.dart';
import 'package:rentals/core/utils/validators.dart';

class RentForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final TextEditingController descriptionController;
  final TextEditingController depositController;
  final TextEditingController priceController;
  final TextEditingController locationController;
  final TextEditingController phoneController;
  final Widget categorySelector;

  final String selectedDuration;
  final ValueChanged<String> onDurationChanged;

  final bool isFetchingLocation;
  final bool isUploading;
  final VoidCallback onLocationTap;
  final VoidCallback onSubmit;

  const RentForm({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.subtitleController,
    required this.descriptionController,
    required this.depositController,
    required this.priceController,
    required this.locationController,
    required this.phoneController,
    required this.categorySelector,
    required this.selectedDuration,
    required this.onDurationChanged,
    required this.isFetchingLocation,
    required this.isUploading,
    required this.onLocationTap,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            "Title",
            controller: titleController,
            customValidator: Validators.validateRequired,
          ),
          const SizedBox(height: 20),

          _buildTextField(
            "Subtitle",
            controller: subtitleController,
            isRequired: false,
          ),
          const SizedBox(height: 20),

          _buildDescriptionField(
            "Description",
            controller: descriptionController,
          ),
          const SizedBox(height: 20),

          _buildTextField(
            "Deposit (Rs)",
            controller: depositController,
            isNumber: true,
            isRequired: false,
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: _buildDurationDropdown()),
              const SizedBox(width: 15),
              Expanded(
                child: _buildTextField(
                  "Price (Rs)",
                  controller: priceController,
                  isNumber: true,
                  customValidator: Validators.validatePrice,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          categorySelector,
          const SizedBox(height: 20),

          _buildActionButtonField(
            "Location",
            locationController.text,
            controller: locationController,
            onActionTap: onLocationTap,
            isFetching: isFetchingLocation,
            buttonLabel: "Set Location",
          ),
          const SizedBox(height: 20),

          _buildTextField(
            "Phone Number",
            controller: phoneController,
            isNumber: true,
            hint: "e.g. 9876543210",
            customValidator: Validators.validatePhone,
          ),
          const SizedBox(height: 40),

          // Submit Button
          Center(
            child: GestureDetector(
              onTap: isUploading ? null : onSubmit,
              child: Container(
                width: 220,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFF16BCE6),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF16BCE6).withOpacity(0.5),
                      const Color(0xFF00A2FF).withOpacity(0.5),
                    ],
                  ),
                ),
                child: Center(
                  child: isUploading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF0D3454),
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Submit",
                          style: TextStyle(
                            color: Color(0xFF0D3454),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    bool isNumber = false,
    bool isRequired = true,
    String? hint,
    bool readOnly = false,
    String? Function(String?)? customValidator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator:
          customValidator ??
          (isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  return null;
                }
              : null),
      style: const TextStyle(color: Color(0xFF0D3454)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        labelStyle: const TextStyle(
          color: Color(0xFF0D3454),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0D3454)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF16BCE6), width: 2),
        ),
      ),
    );
  }

  Widget _buildDescriptionField(
    String label, {
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Required';
        return null;
      },
      style: const TextStyle(color: Color(0xFF0D3454)),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        labelStyle: const TextStyle(
          color: Color(0xFF0D3454),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0D3454)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF16BCE6), width: 2),
        ),
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedDuration,
      decoration: const InputDecoration(
        labelText: "Duration",
        labelStyle: TextStyle(
          color: Color(0xFF0D3454),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0D3454)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF16BCE6), width: 2),
        ),
      ),
      items: ['per hour', 'per day', 'per week', 'per month'].map((
        String value,
      ) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) onDurationChanged(newValue);
      },
    );
  }

  Widget _buildActionButtonField(
    String label,
    String hint, {
    required TextEditingController controller,
    required VoidCallback onActionTap,
    bool isFetching = false,
    required String buttonLabel,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _buildTextField(
            label,
            controller: controller,
            hint: hint,
            readOnly: true,
            customValidator: (value) {
              if (value == null ||
                  value.trim().isEmpty ||
                  value.contains("Detecting") ||
                  value.contains("Failed") ||
                  value.contains("Denied")) {
                return 'Please select a valid location';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 15),
        ElevatedButton(
          onPressed: isFetching ? null : onActionTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16BCE6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
          child: isFetching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  buttonLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
