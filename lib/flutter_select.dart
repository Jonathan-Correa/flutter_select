library flutter_select;

import 'package:flutter/material.dart';
import 'package:flutter_select/utils/default_values.dart';

class FSelect<T> extends StatefulWidget {
  final T? value;
  final bool readOnly;
  final String? title;
  final String? label;
  final double? height;
  final List<T> options;
  final Icon? labelIcon;
  final bool? background;
  final bool? enableInput;
  final String? placeholder;
  final double? modalHeight;
  final Color? selectedColor;
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

  final bool Function(T item, String searchTerm)? onSearch;
  final InputDecoration? searchDecoration;
  final InputDecoration? inputDecoration;

  const FSelect({
    Key? key,
    this.label,
    this.title,
    this.value,
    this.height,
    this.validate,
    this.onSearch,
    this.labelIcon,
    this.background,
    this.enableInput,
    this.placeholder,
    this.modalHeight,
    this.itemBuilder,
    this.emptyBuilder,
    this.selectedColor,
    this.labelAlignment,
    this.labelTextStyle,
    this.onFieldSumitted,
    this.inputDecoration,
    this.searchDecoration,
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
  T? _selectedItem;
  bool hasError = false;
  bool _userIsSearching = false;
  bool isPasswordVisible = false;
  late final TextEditingController _controller;

  bool get canSearch => widget.onSearch != null;

  @override
  void initState() {
    _selectedItem = widget.value;
    _controller = TextEditingController();

    if (_selectedItem != null) {
      _controller.text = widget.itemAsString(_selectedItem!);
    }

    super.initState();
  }

  void _selectInitialValue() async {
    if (widget.value == null) {
      _clearSelectedItem();
      return;
    }

    final selected = widget.options.indexWhere(
      (el) => widget.itemAsValue(el) == widget.itemAsValue(widget.value!),
    );

    if (selected == -1) {
      _clearSelectedItem();
      return;
    }

    final selectedItem = widget.options[selected];
    await Future.delayed(Duration.zero, () {
      _controller.text = widget.itemAsString(selectedItem);
    });

    setState(() {
      _selectedItem = selectedItem;
    });
  }

  @override
  void didUpdateWidget(covariant FSelect<T> oldWidget) {
    if ((oldWidget.value == null && widget.value != null) ||
        (oldWidget.value != null && widget.value == null) ||
        (oldWidget.value != null &&
            widget.value != null &&
            widget.itemAsValue(oldWidget.value!) !=
                widget.itemAsValue(widget.value!))) {
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
        decoration: _buildInputDecoration(context),
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
              _LabelText(text: widget.label!, textStyle: widget.labelTextStyle)
            ],
          ),
          const SizedBox(height: 5),
          input,
        ],
      );
    }

    return input;
  }

  void _clearSelectedItem() async {
    await Future.delayed(Duration.zero, () {
      _controller.clear();
    });

    setState(() => _selectedItem = null);
  }

  void _onTapItem(T item) {
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

  void _onTapContainer() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _ItemList(
          options: widget.options,
          onSearch: widget.onSearch,
          modalHeight: widget.modalHeight,
          emptyBuilder: widget.emptyBuilder,
          searchDecoration: widget.searchDecoration,
          itemBuilder:
              widget.itemBuilder != null ? _itemBuilder : _defaultItemBuilder,
        );
      },
    );

    if (_userIsSearching) {
      setState(() => _userIsSearching = false);
    }
  }

  Widget _itemBuilder(BuildContext context, T item) {
    final isSelected = _selectedItem != null &&
        widget.itemAsValue(_selectedItem!) == widget.itemAsValue(item);

    return InkWell(
      onTap: () => _onTapItem(item),
      child: widget.itemBuilder!(context, item, isSelected),
    );
  }

  Widget _defaultItemBuilder(BuildContext context, T item) {
    final isSelected = _selectedItem != null &&
        widget.itemAsValue(_selectedItem!) == widget.itemAsValue(item);
    final defaultColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () => _onTapItem(item),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isSelected
                ? widget.selectedColor ?? defaultColor
                : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(widget.itemAsString(item)),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context) {
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

    if (widget.inputDecoration != null) {
      return widget.inputDecoration!.copyWith(
        suffixIcon: widget.inputDecoration!.suffixIcon ?? suffixIcon,
        filled: widget.inputDecoration!.filled ?? widget.background,
        hintText: widget.inputDecoration!.hintText ?? widget.placeholder,
        contentPadding: widget.inputDecoration!.contentPadding ??
            const EdgeInsets.fromLTRB(20, 0, 0, 0),
      );
    }

    return buildInputBasicDecoration(context).copyWith(
      suffixIcon: suffixIcon,
      filled: widget.background,
      hintText: widget.placeholder,
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
    );
  }
}

class _ItemList<T> extends StatefulWidget {
  const _ItemList({
    Key? key,
    this.onSearch,
    this.modalHeight,
    this.emptyBuilder,
    required this.options,
    this.searchDecoration,
    required this.itemBuilder,
  }) : super(key: key);

  final List<T> options;
  final double? modalHeight;
  final bool Function(T item, String value)? onSearch;
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final InputDecoration? searchDecoration;

  @override
  State<_ItemList<T>> createState() => __ItemListState<T>();
}

class __ItemListState<T> extends State<_ItemList<T>> {
  late List<T> _options;
  bool _userIsSearching = false;

  bool get canSearch => widget.onSearch != null;

  @override
  void initState() {
    _options = widget.options;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    Widget itemsList;

    if (_options.isEmpty) {
      itemsList = widget.emptyBuilder != null
          ? widget.emptyBuilder!(context)
          : const EmptyOptions();
    } else {
      itemsList = ListView.builder(
        itemCount: _options.length,
        itemBuilder: (context, index) => widget.itemBuilder(
          context,
          _options[index],
        ),
      );
    }

    return Container(
      color: Colors.transparent,
      height: widget.modalHeight ??
          screenSize.height * (_userIsSearching ? 0.8 : 0.4),
      child: Container(
        padding: const EdgeInsets.only(top: 25, bottom: 5, left: 10, right: 10),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        child: canSearch && widget.options.isNotEmpty
            ? Column(
                children: [
                  _InputSearch(
                    onChange: (value) {
                      if (value.isEmpty) {
                        return setState(() => _options = widget.options);
                      }

                      final options = widget.options
                          .where((e) => widget.onSearch!(e, value))
                          .toList();

                      setState(() => _options = options);
                    },
                    buildDecoration: _buildSearchDecoration,
                    onTap: () {
                      if (_userIsSearching == false) {
                        setState(() => _userIsSearching = true);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: itemsList),
                ],
              )
            : itemsList,
      ),
    );
  }

  InputDecoration _buildSearchDecoration() {
    if (widget.searchDecoration != null) return widget.searchDecoration!;

    return InputDecoration(
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 0, 8),
      prefixIcon: const Icon(Icons.search),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(width: 2),
        borderRadius: BorderRadius.circular(5),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(5),
      ),
      border: InputBorder.none,
    );
  }
}

class _InputSearch extends StatelessWidget {
  const _InputSearch({
    Key? key,
    required this.onTap,
    required this.onChange,
    required this.buildDecoration,
  }) : super(key: key);

  final void Function() onTap;
  final void Function(String) onChange;
  final InputDecoration Function() buildDecoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: double.infinity,
      child: TextField(
        onTap: onTap,
        onChanged: onChange,
        decoration: buildDecoration(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}

class _LabelText extends StatelessWidget {
  const _LabelText({
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
