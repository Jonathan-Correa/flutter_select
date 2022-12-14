import 'package:flutter/material.dart';
import 'package:flutter_select/utils/default_values.dart';

class FSelect<T> extends StatefulWidget {
  final T? value;
  final double? height;
  final bool? readOnly;
  final List<T> options;
  final String? placeholder;
  final double? modalHeight;
  final Color? selectedColor;
  final void Function(T? value) onChange;
  final String? Function(T? value)? validate;
  final Widget Function(BuildContext context, T item, bool isSelected)?
      itemBuilder;
  final String Function(T item) itemAsString;
  final dynamic Function(T item) itemAsValue;
  final Widget Function(BuildContext context)? emptyBuilder;

  final InputDecoration? inputDecoration;
  final InputDecoration? searchDecoration;
  final bool Function(T item, String searchTerm)? onSearch;

  const FSelect({
    Key? key,
    this.value,
    this.height,
    this.validate,
    this.onSearch,
    this.readOnly,
    this.placeholder,
    this.modalHeight,
    this.itemBuilder,
    this.emptyBuilder,
    this.selectedColor,
    this.inputDecoration,
    this.searchDecoration,
    required this.options,
    required this.onChange,
    required this.itemAsValue,
    required this.itemAsString,
  }) : super(key: key);

  @override
  _FSelectState<T> createState() => _FSelectState<T>();
}

class _FSelectState<T> extends State<FSelect<T>>
    with AutomaticKeepAliveClientMixin<FSelect<T>> {
  @override
  bool get wantKeepAlive => true;
  T? _selectedItem;
  bool hasError = false;
  bool _userIsSearching = false;
  bool isPasswordVisible = false;
  late final TextEditingController _controller;

  bool get canSearch => widget.onSearch != null;

  double get height {
    var userHeight = widget.height ?? 40;
    userHeight = userHeight < 25 ? 25 : userHeight;
    userHeight = userHeight > 48 ? 48 : userHeight;

    /// min height = 25.0 && max height = 48.0
    return userHeight + (hasError ? 20 : 0);
  }

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
    final isFirstSelection = oldWidget.value == null && widget.value != null;
    final isClearingSelection = oldWidget.value != null && widget.value == null;
    final isChangingSelection = oldWidget.value != null &&
        widget.value != null &&
        widget.itemAsValue(oldWidget.value!) !=
            widget.itemAsValue(widget.value!);

    if (isFirstSelection || isClearingSelection || isChangingSelection) {
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
    super.build(context);
    return SizedBox(
      height: height,
      child: TextFormField(
        readOnly: true,
        controller: _controller,
        decoration: _buildInputDecoration(context),
        onTap: widget.readOnly == true ? null : _onTapContainer,
        validator: (value) {
          String? message;

          if (widget.validate != null) {
            message = widget.validate!(_selectedItem);
            setState(() => hasError = message != null);
          }

          return message;
        },
      ),
    );
  }

  void _clearSelectedItem() async {
    await Future.delayed(Duration.zero, () => _controller.clear());
    setState(() => _selectedItem = null);
  }

  void _onTapItem(T item) {
    if (_selectedItem != null &&
        widget.itemAsValue(item) == widget.itemAsValue(_selectedItem!)) {
      return Navigator.of(context).pop();
    }

    _selectedItem = item;
    widget.onChange(item);
    _controller.text = widget.itemAsString(item);
    Navigator.of(context).pop();
  }

  void _onTapContainer() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    final defaultColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => _onTapItem(item),
      child: Card(
        color: isSelected ? widget.selectedColor ?? defaultColor : null,
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
    var suffixIconsSize = (height - 20) - (hasError ? 20 : 0);
    suffixIconsSize = suffixIconsSize < 15 ? 15 : suffixIconsSize;

    Widget suffixIcon = Icon(
      Icons.arrow_drop_down,
      size: suffixIconsSize,
    );

    if (_selectedItem != null && widget.readOnly != true) {
      suffixIcon = Container(
        width: suffixIconsSize + 50,
        margin: const EdgeInsets.only(right: 10),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.cancel_sharp, size: suffixIconsSize),
              onPressed: () {
                _controller.clear();
                _selectedItem = null;
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
        hintText: widget.inputDecoration!.hintText ?? widget.placeholder,
      );
    }

    return const InputDecoration().copyWith(
      suffixIcon: suffixIcon,
      hintText: widget.placeholder,
    );
  }
}

class _ItemList<T> extends StatefulWidget {
  const _ItemList({
    Key? key,
    this.onSearch,
    this.modalHeight,
    this.emptyBuilder,
    this.searchDecoration,
    required this.options,
    required this.itemBuilder,
  }) : super(key: key);

  final List<T> options;
  final double? modalHeight;
  final InputDecoration? searchDecoration;
  final bool Function(T item, String value)? onSearch;
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget Function(BuildContext context, T item) itemBuilder;

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

    return SizedBox(
      height: widget.modalHeight ??
          screenSize.height * (_userIsSearching ? 0.8 : 0.4),
      child: Container(
        padding: const EdgeInsets.only(top: 25, bottom: 5, left: 10, right: 10),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
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
        borderSide: const BorderSide(width: 2, color: Colors.green),
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
