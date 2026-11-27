import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Fetches live USD prices with zero API keys. Results are cached on each
/// holding in SQLite by the caller, so the vaults still show the last known
/// price offline.
abstract interface class MarketPriceService {
  /// Prices keyed by the symbols exactly as passed in. Symbols that fail to
  /// resolve are simply missing from the map (never throws).
  Future<Map<String, double>> fetchPrices({
    List<String> quoteSymbols = const [],
    List<String> cryptoSymbols = const [],
  });
}

/// Offline / test implementation that never touches the network.
class OfflineMarketPriceService implements MarketPriceService {
  const OfflineMarketPriceService([this.prices = const {}]);

  final Map<String, double> prices;

  @override
  Future<Map<String, double>> fetchPrices({
    List<String> quoteSymbols = const [],
    List<String> cryptoSymbols = const [],
  }) async => {
        for (final s in [...quoteSymbols, ...cryptoSymbols])
          if (prices.containsKey(s)) s: prices[s]!,
      };
}

/// CoinGecko `/simple/price` for crypto; Yahoo Finance chart JSON for
/// stocks, ETFs, ESPP shares and silver/gold spot (via futures symbols).
class HttpMarketPriceService implements MarketPriceService {
  HttpMarketPriceService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 10);
  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'Mozilla/5.0 (compatible; SquirrelStash/1.1)',
  };

  /// Common crypto symbols → CoinGecko ids (anything else is used as an id).
  static const cryptoIds = {
    'BTC': 'bitcoin', 'ETH': 'ethereum', 'SOL': 'solana', 'DOGE': 'dogecoin',
    'ADA': 'cardano', 'XRP': 'ripple', 'LTC': 'litecoin', 'DOT': 'polkadot',
    'AVAX': 'avalanche-2', 'LINK': 'chainlink', 'SHIB': 'shiba-inu',
    'MATIC': 'matic-network', 'POL': 'matic-network', 'USDC': 'usd-coin',
    'USDT': 'tether', 'BNB': 'binancecoin', 'XLM': 'stellar',
  };

  /// Friendly metal names → Yahoo futures symbols (spot proxy, USD per oz).
  static const metalAliases = {
    'SILVER': 'SI=F', 'XAG': 'SI=F', 'XAGUSD': 'SI=F',
    'GOLD': 'GC=F', 'XAU': 'GC=F', 'XAUUSD': 'GC=F',
  };

  static String coingeckoId(String symbol) =>
      cryptoIds[symbol.trim().toUpperCase()] ?? symbol.trim().toLowerCase();

  static String yahooSymbol(String symbol) {
    final s = symbol.trim().toUpperCase();
    return metalAliases[s] ?? s;
  }

  @override
  Future<Map<String, double>> fetchPrices({
    List<String> quoteSymbols = const [],
    List<String> cryptoSymbols = const [],
  }) async {
    final out = <String, double>{};
    if (cryptoSymbols.isNotEmpty) out.addAll(await _crypto(cryptoSymbols));
    final quotes = await Future.wait(quoteSymbols.toSet().map((s) async => (s, await _quote(s))));
    for (final (symbol, price) in quotes) {
      if (price != null) out[symbol] = price;
    }
    return out;
  }

  Future<Map<String, double>> _crypto(List<String> symbols) async {
    final ids = {for (final s in symbols) s: coingeckoId(s)};
    final uri = Uri.https('api.coingecko.com', '/api/v3/simple/price', {
      'ids': ids.values.toSet().join(','),
      'vs_currencies': 'usd',
    });
    try {
      final res = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return const {};
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final out = <String, double>{};
      ids.forEach((symbol, id) {
        final usd = (json[id] as Map<String, dynamic>?)?['usd'];
        if (usd is num) out[symbol] = usd.toDouble();
      });
      return out;
    } catch (error) {
      debugPrint('SquirrelStash prices: crypto fetch failed ($error)');
      return const {};
    }
  }

  Future<double?> _quote(String symbol) async {
    final uri = Uri.https('query1.finance.yahoo.com',
        '/v8/finance/chart/${Uri.encodeComponent(yahooSymbol(symbol))}',
        {'interval': '1d', 'range': '1d'});
    try {
      final res = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final result = (json['chart']?['result'] as List?)?.firstOrNull;
      final price = (result as Map<String, dynamic>?)?['meta']?['regularMarketPrice'];
      return price is num ? price.toDouble() : null;
    } catch (error) {
      debugPrint('SquirrelStash prices: quote $symbol failed ($error)');
      return null;
    }
  }
}
