library flutter_select;

import 'package:flutter/material.dart';
import 'package:flutter_select/utils/default_values.dart';

class FSelect<T> extends StatefulWidget {
  final bool readOnly;
  final String? title;
  final String? label;
  final double? height;
  final double? modalHeight;
  final Icon? labelIcon;
  final bool? background;
  final bool? enableInput;
  final String? placeholder;
  final TextStyle? labelTextStyle;
  final void Function(T? value) onChange;
  final MainAxisAlignment? labelAlignment;
  final String? Function(String? value)? validate;
  final void Function(String value)? onFieldSumitted;
  final Widget Function(BuildContext context, T item, bool isSelected)?
      itemBuilder;
  final String Function(T item) itemAsString;
  final Widget Function(BuildContext context)? emptyBuilder;
  final dynamic Function(T item) itemAsValue;
  final List<T> options;
  final T? value;

  const FSelect({
    Key? key,
    this.label,
    this.title,
    this.value,
    this.height,
    this.validate,
    this.labelIcon,
    this.background,
    this.enableInput,
    this.placeholder,
    this.modalHeight,
    this.itemBuilder,
    this.emptyBuilder,
    this.labelAlignment,
    this.labelTextStyle,
    this.onFieldSumitted,
    this.readOnly = false,
    required this.options,
    required this.onChange,
    required this.itemAsValue,
    required this.itemAsString,
  }) : super(key: key);

  @override
  _InputBasicState<T> createState() => _InputBasicState<T>();
}

class _InputBasicState<T> extends State<FSelect<T>> {
  bool isPasswordVisible = false;
  bool hasError = false;
  T? _selectedItem;
  late final TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController();
    _selectedItem = widget.value;

    if (_selectedItem != null) {
      _controller.text = widget.itemAsString(_selectedItem!);
    }

    super.initState();
  }

  void _selectInitialValue() {
    if (widget.value == null) {
      _controller.clear();
      setState(() => _selectedItem = null);
      return;
    }

    final selected = widget.options.indexWhere(
      (el) => widget.itemAsValue(el) == widget.itemAsValue(widget.value!),
    );

    if (selected == -1) {
      _controller.clear();
      setState(() => _selectedItem = null);
      return;
    }

    final selectedItem = widget.options[selected];
    _controller.text = widget.itemAsString(selectedItem);
    setState(() => _selectedItem = selectedItem);
  }

  @override
  void didUpdateWidget(covariant FSelect<T> oldWidget) {
    if (oldWidget.value != widget.value) {
      _selectInitialValue();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const heightSpace = SizedBox(height: 18.5);

    final input = SizedBox(
      height: (widget.height ?? 40) + (hasError ? 20 : 0),
      child: TextFormField(
        readOnly: true,
        onTap: _onTapContainer,
        validator: (value) {
          String? message;

          if (widget.validate != null) {
            message = widget.validate!(value);
          }

          setState(() => hasError = message != null);
          return message;
        },
        controller: _controller,
        enabled: widget.enableInput,
        onFieldSubmitted: widget.onFieldSumitted,
        decoration: buildInputDecoration(context),
        style: TextStyle(
          height: 1.3,
          fontFamily: 'Cabin',
          fontSize: screenSize.width * 0.04,
        ),
      ),
    );

    if (widget.label != null) {
      return Column(
        children: [
          heightSpace,
          Row(
            mainAxisAlignment:
                widget.labelAlignment ?? MainAxisAlignment.center,
            children: [
              if (widget.labelIcon != null) widget.labelIcon!,
              if (widget.labelIcon != null) const SizedBox(width: 3),
              LabelText(text: widget.label!, textStyle: widget.labelTextStyle)
            ],
          ),
          const SizedBox(height: 5),
          input,
        ],
      );
    }

    return input;
  }

  void _onTapItem(int index) {
    final item = widget.options[index];

    if (_selectedItem != null &&
        widget.itemAsValue(item) == widget.itemAsValue(_selectedItem!)) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _selectedItem = item);
    widget.onChange(item);
    _controller.text = widget.itemAsString(item);
    Navigator.of(context).pop();
  }

  Widget _defaultItemBuilder(BuildContext context, int index) {
    return InkWell(
      onTap: () => _onTapItem(index),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(widget.itemAsString(widget.options[index])),
        ),
      ),
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final option = widget.options[index];
    final isSelected = _selectedItem != null &&
        widget.itemAsValue(_selectedItem!) == widget.itemAsValue(option);

    return InkWell(
      onTap: () => _onTapItem(index),
      child: widget.itemBuilder!(context, option, isSelected),
    );
  }

  void _onTapContainer() {
    final screenSize = MediaQuery.of(context).size;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          color: Colors.transparent,
          height: widget.modalHeight ?? screenSize.height * 0.4,
          child: Container(
            padding: const EdgeInsets.only(top: 25, bottom: 5),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30.0),
                topRight: Radius.circular(30.0),
              ),
            ),
            child: widget.options.isEmpty
                ? (widget.emptyBuilder != null
                    ? widget.emptyBuilder!(context)
                    : const EmptyOptions())
                : ListView.builder(
                    itemCount: widget.options.length,
                    itemBuilder: widget.itemBuilder != null
                        ? _itemBuilder
                        : _defaultItemBuilder,
                  ),
          ),
        );
      },
    );
  }

  InputDecoration buildInputDecoration(BuildContext context) {
    Widget suffixIcon = const Icon(Icons.arrow_drop_down);

    if (_selectedItem != null) {
      suffixIcon = Container(
        width: 72,
        margin: const EdgeInsets.only(right: 10),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.cancel_sharp),
              onPressed: () {
                _controller.clear();
                setState(() => _selectedItem = null);
                widget.onChange(null);
              },
            ),
            suffixIcon,
          ],
        ),
      );
    }

    return buildBasicInputDecoration(context).copyWith(
      suffixIcon: suffixIcon,
      filled: widget.background,
      hintText: widget.placeholder,
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
    );
  }
}

InputDecoration buildBasicInputDecoration(BuildContext context) {
  final theme = Theme.of(context);

  return InputDecoration(
    fillColor: Theme.of(context).scaffoldBackgroundColor,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: theme.primaryColor),
      borderRadius: BorderRadius.circular(42.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: theme.colorScheme.primary,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(42.0),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(42.0),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(42.0),
    ),
    border: InputBorder.none,
  );
}

class LabelText extends StatelessWidget {
  const LabelText({
    this.textStyle,
    required this.text,
    Key? key,
  }) : super(key: key);

  final String text;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizeScreen = MediaQuery.of(context).size;

    return Text(
      text,
      textScaleFactor: sizeScreen.width * 0.0028,
      style: textStyle ??
          theme.textTheme.headline6!.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
