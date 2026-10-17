import 'package:flutter/material.dart';

import '../weather_models.dart';

class CitySearchPage extends StatefulWidget {
  const CitySearchPage({
    super.key,
    this.searchCities,
    this.searchCity,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.frameTop,
    required this.frameBottom,
    required this.surface,
    required this.surfaceAlt,
    required this.edge,
    required this.accent,
    required this.highlight,
    required this.text,
    required this.muted,
  }) : assert(
          searchCities != null || searchCity != null,
          'Either searchCities or searchCity must be provided',
        );

  final Future<List<PlaceResult>> Function(String query)? searchCities;
  final Future<PlaceResult?> Function(String query)? searchCity;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color frameTop;
  final Color frameBottom;
  final Color surface;
  final Color surfaceAlt;
  final Color edge;
  final Color accent;
  final Color highlight;
  final Color text;
  final Color muted;

  @override
  State<CitySearchPage> createState() => _CitySearchPageState();
}

class _CitySearchPageState extends State<CitySearchPage> {
  final _controller = TextEditingController();
  bool _searching = false;
  String? _message;
  List<PlaceResult> _results = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searching) return;
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _message = 'Please enter a city name.';
        _results = const [];
      });
      return;
    }

    setState(() {
      _searching = true;
      _message = null;
      _results = const [];
    });

    List<PlaceResult> matches = const [];
    if (widget.searchCities != null) {
      matches = await widget.searchCities!(query);
    } else if (widget.searchCity != null) {
      final single = await widget.searchCity!(query);
      if (single != null) matches = [single];
    }

    if (!mounted) return;
    setState(() => _searching = false);

    if (matches.isEmpty) {
      setState(() => _message = 'No matching city found. Try another name.');
    } else if (matches.length == 1) {
      Navigator.of(context).pop(matches.first);
    } else {
      setState(() {
        _results = matches;
        _message = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundBottom,
      appBar: AppBar(
        backgroundColor: widget.frameTop,
        foregroundColor: widget.text,
        title: const Text('Choose a city',
            style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: ColoredBox(
              color: widget.edge, child: const SizedBox(height: 1.5)),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.backgroundTop,
              widget.backgroundBottom,
              widget.backgroundTop,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.surfaceAlt, widget.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: widget.edge, width: 1.5),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                        color: widget.backgroundTop.withValues(alpha: .65),
                        offset: const Offset(0, 4),
                        blurRadius: 7),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      style: TextStyle(color: widget.text),
                      decoration: InputDecoration(
                        labelText: 'City name',
                        labelStyle: TextStyle(color: widget.muted),
                        hintStyle: TextStyle(color: widget.muted),
                        prefixIcon:
                            Icon(Icons.location_city, color: widget.accent),
                        filled: true,
                        fillColor: widget.backgroundBottom,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: widget.edge),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: widget.accent, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.accent,
                        foregroundColor: widget.text,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(color: widget.frameBottom),
                        ),
                      ),
                      onPressed: _searching ? null : _search,
                      icon: _searching
                          ? SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: widget.highlight),
                            )
                          : const Icon(Icons.search),
                      label: Text(_searching ? 'SEARCHING' : 'SEARCH'),
                    ),
                  ],
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: widget.text),
                ),
              ],
              if (_results.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Matching places (${_results.length}):',
                  style: TextStyle(
                    color: widget.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final place = _results[index];
                      return Material(
                        color: widget.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(color: widget.edge),
                        ),
                        child: ListTile(
                          title: Text(
                            place.city,
                            style: TextStyle(
                              color: widget.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: place.region.isNotEmpty
                              ? Text(
                                  place.region,
                                  style: TextStyle(color: widget.muted),
                                )
                              : null,
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: widget.accent,
                          ),
                          onTap: () => Navigator.of(context).pop(place),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
