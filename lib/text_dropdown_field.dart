import 'package:flutter/material.dart';

class TextDropdownField<T extends Object> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T)? itemToString;
  final void Function(T) onSelected;
  final String? hintText;
  final T? initialValue;
  final Function(T item, T? selectedItem)? compareFn;
  final InputDecoration? inputDecoration;
  final double? maxHeight;
  final double? minHeight;

  const TextDropdownField({
    super.key,
    required this.items,
    this.itemToString,
    required this.onSelected,
    this.hintText,
    required this.title,
    this.initialValue,
    this.compareFn,
    this.inputDecoration, this.maxHeight = 250, this.minHeight,
  });

  @override
  State<TextDropdownField<T>> createState() =>
      _TextDropdownFieldState<T>();
}

class _TextDropdownFieldState<T extends Object>
    extends State<TextDropdownField<T>>
    with WidgetsBindingObserver {
  final GlobalKey<FormFieldState<String>> _fieldKey = GlobalKey();
  bool _openUp = false;
  FocusNode? _focusNode;
  T? selectedValue;
  late String Function(T) _itemToString;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
    _itemToString = widget.itemToString ?? (item) => item.toString();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    final height = MediaQuery.of(context).size.height;
    var h = height / View.of(context).display.size.height;
    if (h < (height * 0.2)) {
      return;
    }
    final keyboardHeight = bottomInset * h;
    _updateMenuDirection(keyboardHeight);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.items.isNotEmpty, 'Items list cannot be empty');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 5,
      children: [
        Text(
          widget.title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        RawAutocomplete<T>(
          initialValue: selectedValue != null
              ? TextEditingValue(text: _itemToString(selectedValue!))
              : null,
          optionsViewOpenDirection: _openUp
              ? OptionsViewOpenDirection.up
              : OptionsViewOpenDirection.down,
          optionsBuilder: (TextEditingValue value) {
            if (value.text.isEmpty) {
              return widget.items;
            }
            return widget.items.where(
                  (item) => _itemToString(
                item,
              ).toLowerCase().contains(value.text.toLowerCase()),
            );
          },
          displayStringForOption: _itemToString,
          onSelected: widget.onSelected,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _focusNode = focusNode;
            return TextFormField(
              key: _fieldKey,
              controller: controller,
              focusNode: focusNode,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 10,
                ),
                hintText: widget.hintText,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints:  BoxConstraints(maxHeight: widget.maxHeight??double.infinity),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      title: Text(_itemToString(option)),
                      onTap: () {
                        _focusNode?.unfocus();
                        onSelected(option);
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _updateMenuDirection(double keyboardHeight) {
    final renderBox =
    _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final fieldOffset = renderBox.localToGlobal(Offset.zero);
    final fieldHeight = renderBox.size.height;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    final spaceBelow =
        screenHeight - keyboardHeight - (fieldOffset.dy + fieldHeight);
    final spaceAbove = fieldOffset.dy;

    _openUp = spaceBelow < 250 && spaceAbove > spaceBelow;
  }
}
