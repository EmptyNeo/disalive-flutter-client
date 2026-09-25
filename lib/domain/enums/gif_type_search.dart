enum GifTypeSearch {
  searchGifs('search_gifs'),
  popular('popular');

  final String value;

  const GifTypeSearch(this.value);

  static GifTypeSearch fromString(String? value) {
    if (value == null) return GifTypeSearch.popular;
    for (final type in GifTypeSearch.values) {
      if (type.value == value) {
        return type;
      }
    }
    
    return GifTypeSearch.popular;
  }
}
