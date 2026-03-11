import 'package:flutter/material.dart';

class RentForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final TextEditingController descriptionController;
  final TextEditingController depositController;
  final TextEditingController priceController;
  final TextEditingController locationController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final Widget categorySelector;

  final String selectedDuration;
  final ValueChanged<String> onDurationChanged;

  final bool isFetchingLocation;
  final bool isUploading;
  final VoidCallback onLocationTap;
  final VoidCallback onSubmit;

  final Color primaryDarkBlue = const Color(0xFF113F67);
  final Color lightFillColor = const Color(0xFFE5F4F9);

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
    required this.emailController,
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
            Image.asset('assets/icons/title_icon.png', height: 14),
            controller: titleController,
          ),
          _buildTextField(
            "Subtitle",
            Image.asset('assets/icons/subtitle_icon.png', height: 14),
            controller: subtitleController,
          ),
          _buildDescriptionField(
            "Description",
            Image.asset('assets/icons/description_icon.png', height: 14),
            controller: descriptionController,
          ),

          _buildTextField(
            "Deposite",
            Image.asset('assets/icons/deposite_icon.png', height: 16),
            controller: depositController,
            isNumber: true,
          ),

          _buildTextField(
            "Price",
            Image.asset('assets/icons/price_icon.png', height: 14),
            hintText: "Rs. 00",
            controller: priceController,
            isNumber: true,
          ),

          _buildDropdownField(
            "Duration",
            Image.asset('assets/icons/duration_icon.png', height: 14),
          ),

          categorySelector,

          _buildActionButtonField(
            "Location",
            Image.asset('assets/icons/location_icon2.png', height: 14),
            controller: locationController,
            onActionTap: onLocationTap,
            isFetching: isFetchingLocation,
          ),

          // --- STRICT 10-DIGIT PHONE NUMBER LOGIC ADDED HERE ---
          _buildActionButtonField(
            "Number",
            Image.asset('assets/icons/phone_icon.png', height: 14),
            controller: phoneController,
            isNumber: true,
            maxLength: 10, // Stops user from typing more than 10 digits
            customValidator: (value) {
              if (value == null || value.trim().isEmpty) return 'Required';
              if (value.length != 10) return 'Must be exactly 10 digits';
              if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Digits only';
              return null;
            },
          ),

          _buildActionButtonField(
            "Email",
            Image.asset('assets/icons/email_icon2.png', height: 16),
            controller: emailController,
          ),

          const SizedBox(height: 25),

          // --- SUBMIT BUTTON ---
          GestureDetector(
            onTap: isUploading ? null : onSubmit,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: primaryDarkBlue,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/submit_icon.png',
                            height: 20,
                            width: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Submit",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                              decorationThickness: 1.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 45),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(
    String label,
    Widget iconWidget, {
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: 5,
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required' : null,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.blueGrey,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: lightFillColor,
          isDense: true,
          contentPadding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 15, right: 8, bottom: 85),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                const SizedBox(width: 8),
                Text(
                  "$label : ",
                  style: TextStyle(
                    color: primaryDarkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primaryDarkBlue, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primaryDarkBlue, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    Widget iconWidget, {
    String? hintText,
    TextEditingController? controller,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required' : null,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.blueGrey,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: lightFillColor,
          isDense: true,
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 15, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                const SizedBox(width: 8),
                Text(
                  "$label : ",
                  style: TextStyle(
                    color: primaryDarkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primaryDarkBlue, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primaryDarkBlue, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, Widget iconWidget) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: selectedDuration,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.blueGrey,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: lightFillColor,
          isDense: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 15, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                const SizedBox(width: 8),
                Text(
                  "$label : ",
                  style: TextStyle(
                    color: primaryDarkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primaryDarkBlue, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primaryDarkBlue, width: 1.5),
          ),
        ),
        icon: Icon(Icons.keyboard_arrow_down, color: primaryDarkBlue, size: 24),
        items: <String>['Per Day', 'Per Week', 'Per Month'].map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: (val) {
          if (val != null) onDurationChanged(val);
        },
      ),
    );
  }

  Widget _buildActionButtonField(
    String label,
    Widget iconWidget, {
    required TextEditingController controller,
    VoidCallback? onActionTap,
    bool isFetching = false,
    bool isNumber = false,
    int? maxLength, // <--- ADDED SUPPORT FOR MAX LENGTH
    String? Function(String?)?
    customValidator, // <--- ADDED SUPPORT FOR CUSTOM VALIDATORS
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: TextFormField(
              controller: controller,
              readOnly: label == "Location",
              keyboardType: isNumber
                  ? TextInputType.number
                  : TextInputType.text,
              maxLength: maxLength, // Hooked up max length
              validator:
                  customValidator ??
                  (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Required';
                    if (label == "Location" &&
                        (value.contains("Detecting") ||
                            value.contains("Failed")))
                      return 'Valid location needed';
                    return null;
                  },
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: lightFillColor,
                isDense: true,
                counterText: "", // Hides the "0/10" text below the field
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 15, right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      iconWidget,
                      const SizedBox(width: 8),
                      Text(
                        "$label : ",
                        style: TextStyle(
                          color: primaryDarkBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: primaryDarkBlue, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: primaryDarkBlue, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          if (onActionTap != null)
            Expanded(
              flex: 4,
              child: GestureDetector(
                onTap: onActionTap,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryDarkBlue,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: isFetching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/icons/change_icon.png',
                                height: 14,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "Change",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
