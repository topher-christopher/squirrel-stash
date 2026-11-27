import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:squirrel_stash/core/market_price_service.dart';

void main() {
  test('parses CoinGecko and Yahoo responses, maps symbols, skips failures', () async {
    final seen = <Uri>[];
    final client = MockClient((req) async {
      seen.add(req.url);
      if (req.url.host == 'api.coingecko.com') {
        return http.Response(jsonEncode({'bitcoin': {'usd': 97123.5}, 'ethereum': {'usd': 3500}}), 200);
      }
      final symbol = Uri.decodeComponent(req.url.pathSegments.last);
      if (symbol == 'NOPE') return http.Response('not found', 404);
      final price = {'VTI': 287.4, 'SI=F': 31.25}[symbol];
      return http.Response(jsonEncode({
        'chart': {
          'result': [
            {'meta': {'regularMarketPrice': price}},
          ],
        },
      }), 200);
    });
    final service = HttpMarketPriceService(client: client);
    final prices = await service.fetchPrices(quoteSymbols: ['VTI', 'silver', 'NOPE'], cryptoSymbols: ['BTC', 'ETH']);
    expect(prices['BTC'], 97123.5);
    expect(prices['ETH'], 3500);
    expect(prices['VTI'], 287.4);
    expect(prices['silver'], 31.25, reason: 'friendly metal names map to SI=F');
    expect(prices.containsKey('NOPE'), isFalse);
    final gecko = seen.firstWhere((u) => u.host == 'api.coingecko.com');
    expect(gecko.queryParameters['ids'], 'bitcoin,ethereum');
    expect(gecko.queryParameters.containsKey('x_cg_demo_api_key'), isFalse, reason: 'no API keys');
  });

  test('network errors resolve to an empty map (offline fallback)', () async {
    final service = HttpMarketPriceService(client: MockClient((_) async => throw Exception('offline')));
    expect(await service.fetchPrices(quoteSymbols: ['VTI'], cryptoSymbols: ['BTC']), isEmpty);
  });
}
