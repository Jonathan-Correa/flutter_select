import 'package:flutter/material.dart';
import 'package:flutter_select/utils/default_values.dart';
import 'package:flutter_select/models/multiple_select_options_manager.dart';

class FMultipleSelect<T> extends StatefulWidget {
  final List<T> values;
  final double inputHeight;
  final bool? disabled;
  final List<T> options;
  final String? placeholder;
  final double? modalHeight;
  final Color? selectedColor;
  final void Function(T? value) onChange;
  final String? Function(T? value)? validator;
  final Widget Function(BuildContext context, T item)? itemBuilder;
  final String Function(T item) itemAsString;
  final dynamic Function(T item) itemAsValue;
  final Widget Function(BuildContext context)? emptyBuilder;

  final InputDecoration? inputDecoration;
  final InputDecoration? searchDecoration;
  final bool Function(T item, String searchTerm)? onSearch;

  const FMultipleSelect({
    Key? key,
    this.onSearch,
    this.disabled,
    this.validator,
    this.placeholder,
    this.modalHeight,
    this.itemBuilder,
    this.emptyBuilder,
    this.selectedColor,
    this.inputDecoration,
    this.inputHeight = 40,
    this.searchDecoration,
    required this.options,
    this.values = const [],
    required this.onChange,
    required this.itemAsValue,
    required this.itemAsString,
  }) : super(key: key);

  @override
  State<FMultipleSelect<T>> createState() => _FMultipleSelectState<T>();
}

class _FMultipleSelectState<T> extends State<FMultipleSelect<T>>
    with AutomaticKeepAliveClientMixin<FMultipleSelect<T>> {
  @override
  bool get wantKeepAlive => true;
  Set<T> _selectedItems = {};
  bool hasError = false;
  bool _userIsSearching = false;
  bool isPasswordVisible = false;
  List<T> _currentOptions = [];

  bool get canSearch => widget.onSearch != null;

  double get height {
    var userHeight = widget.inputHeight;
    userHeight = userHeight < 25 ? 25 : userHeight;
    userHeight = userHeight > 48 ? 48 : userHeight;

    /// min height = 25.0 && max height = 48.0
    return userHeight + (hasError ? 20 : 0);
  }

  @override
  void initState() {
    _currentOptions = widget.options;
    _selectedItems = Set.from(widget.values);
    super.initState();
  }

  void _selectInitialValue() async {
    if (widget.values.isEmpty) {
      _clearSelectedItem();
      return;
    }

    setState(() => _selectedItems = Set.from(widget.values));
  }

  @override
  void didUpdateWidget(covariant FMultipleSelect<T> oldWidget) {
    final isFirstSelection =
        oldWidget.values.isEmpty && widget.values.isNotEmpty;
    final isClearingSelection =
        oldWidget.values.isNotEmpty && widget.values.isEmpty;
    final isChangingSelection =
        oldWidget.values.isNotEmpty && widget.values.isNotEmpty;

    if (isFirstSelection || isClearingSelection || isChangingSelection) {
      print('Setting initial value');
      _selectInitialValue();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    var suffixIconsSize = (height - 20) - (hasError ? 20 : 0);
    suffixIconsSize = suffixIconsSize < 15 ? 15 : suffixIconsSize;

    List<Widget> suffixIcons = widget.disabled != true
        ? [
            const SizedBox(width: 10),
            Icon(
              Icons.arrow_drop_down,
              size: suffixIconsSize,
              color: primaryColor,
            )
          ]
        : [];

    if (_selectedItems.isNotEmpty && widget.disabled == false) {
      suffixIcons = [
        GestureDetector(
          child: Icon(
            Icons.cancel_sharp,
            size: suffixIconsSize,
            color: primaryColor,
          ),
          onTap: () {
            _selectedItems = {};
            widget.onChange(null);
          },
        ),
        ...suffixIcons,
      ];
    }

    final placeholder = Text(
      widget.placeholder ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return GestureDetector(
      onTap: widget.disabled == true ? null : _onTapContainer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red,
          border: Border(
            bottom: BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                child: _selectedItems.isNotEmpty
                    ? Wrap(
                        spacing: 3,
                        runSpacing: 3,
                        children: _selectedItems
                            .map(
                              (e) => _OptionChip(text: widget.itemAsString(e)),
                            )
                            .toList(),
                      )
                    : placeholder,
              ),
            ),
            ...suffixIcons
          ],
        ),
      ),
    );
  }

  void _clearSelectedItem() async {
    setState(() => _selectedItems = {});
  }

  void _onTapItem(T item) {
    _selectedItems.add(item);
    widget.onChange(item);
    Navigator.of(context).pop();

    setState(() {
      _currentOptions.removeWhere((option) => option == item);
    });
  }

  void _onAcceptOptions() {
    print('Hola');
  }

  void _onTapContainer() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ItemList(
          options: _currentOptions,
          onSearch: widget.onSearch,
          modalHeight: widget.modalHeight,
          emptyBuilder: widget.emptyBuilder,
          searchDecoration: widget.searchDecoration,
          itemBuilder: widget.itemBuilder != null
              ? widget.itemBuilder!
              : _defaultItemBuilder,
          onAcceptOptions: _onAcceptOptions,
        );
      },
    );

    if (_userIsSearching) {
      setState(() => _userIsSearching = false);
    }
  }

  Widget _defaultItemBuilder(BuildContext context, T item) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          color: Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(widget.itemAsString(item)),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    Key? key,
    required this.text,
  }) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(text),
      labelPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      deleteIcon: const Icon(Icons.cancel),
      onDeleted: () {},
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
    required this.onAcceptOptions,
  }) : super(key: key);

  final List<T> options;
  final double? modalHeight;
  final InputDecoration? searchDecoration;
  final bool Function(T item, String value)? onSearch;
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final void Function() onAcceptOptions;

  @override
  State<_ItemList<T>> createState() => __ItemListState<T>();
}

class __ItemListState<T> extends State<_ItemList<T>> {
  late List<T> _options;
  late MultipleSelectOptionManager _selectOptionManager;
  bool _userIsSearching = false;

  bool get canSearch => widget.onSearch != null;

  @override
  void initState() {
    _options = widget.options;
    _selectOptionManager = MultipleSelectOptionManager();
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
        itemBuilder: (context, index) => InkWell(
          onTap: () {
            _selectOptionManager.add(_options[index]);
          },
          child: widget.itemBuilder(
            context,
            _options[index],
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.modalHeight ??
          screenSize.height * (_userIsSearching ? 0.8 : 0.4),
      child: Container(
        padding: const EdgeInsets.only(
          bottom: 5,
          left: 10,
          right: 10,
        ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _AcceptButton(
                        onAcceptOptions: widget.onAcceptOptions,
                      )
                    ],
                  ),
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

class _AcceptButton extends StatelessWidget {
  const _AcceptButton({
    Key? key,
    required this.onAcceptOptions,
  }) : super(key: key);

  final void Function() onAcceptOptions;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
      ),
      onPressed: onAcceptOptions,
      child: const Icon(Icons.check),
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
