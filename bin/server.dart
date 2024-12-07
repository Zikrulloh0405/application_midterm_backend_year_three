import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// In-memory database and cart
final data = {
  "1": {
    "name": "Big burger",
    "price": 8.99,
    "images": "big_burger.png",
  },
  "2": {
    "name": "Wendy's",
    "price": 5.00,
    "images": "wendys_burger.png",
  },
  "3": {
    "name": "Black burger",
    "price": 7.67,
    "images": "black_burger.png",
  },
  "4": {
    "name": "Hot Dog",
    "price": 3.50,
    "images": "hot_dog.png",
  },
};

final Map<String, int> cart = {}; // In-memory cart: productId -> quantity

// Configure routes
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/products', _getProductsHandler) // Serve product list
  ..post('/cart', _addToCartHandler) // Add/Increment product in cart
  ..put('/cart', _updateCartHandler) // Decrement product quantity
  ..delete('/cart/<productId>', _deleteFromCartHandler) // Remove product from cart
  ..post('/buy', _buyHandler) // Reset cart on "Buy" button
  ..get('/static/<file>', _staticFileHandler); // Serve static files

// Root handler
Response _rootHandler(Request req) {
  return Response.ok('Welcome to the backend for the e-commerce app!\n');
}

// Products handler
Response _getProductsHandler(Request req) {
  return Response.ok(jsonEncode(data), headers: {
    'Content-Type': 'application/json',
  });
}

// Add or increment product in the cart
Future<Response> _addToCartHandler(Request req) async {
  final body = await req.readAsString();
  final requestData = jsonDecode(body);

  final productId = requestData['productId'];
  if (!data.containsKey(productId)) {
    return Response.notFound('Product not found');
  }

  cart[productId] = (cart[productId] ?? 0) + 1;

  return Response.ok(jsonEncode(cart), headers: {
    'Content-Type': 'application/json',
  });
}

// Decrement product quantity in the cart
Future<Response> _updateCartHandler(Request req) async {
  final body = await req.readAsString();
  final requestData = jsonDecode(body);

  final productId = requestData['productId'];
  if (!cart.containsKey(productId)) {
    return Response.notFound('Product not in cart');
  }

  cart[productId] = cart[productId]! - 1;

  if (cart[productId]! <= 0) {
    cart.remove(productId); // Remove from cart if quantity reaches zero
  }

  return Response.ok(jsonEncode(cart), headers: {
    'Content-Type': 'application/json',
  });
}

// Delete product from cart
Response _deleteFromCartHandler(Request req, String productId) {
  if (!cart.containsKey(productId)) {
    return Response.notFound('Product not in cart');
  }

  cart.remove(productId);

  return Response.ok(jsonEncode(cart), headers: {
    'Content-Type': 'application/json',
  });
}

// Buy handler: Reset cart
Response _buyHandler(Request req) {
  cart.clear();

  return Response.ok(jsonEncode({'message': 'Purchase successful, cart cleared!'}),
      headers: {
        'Content-Type': 'application/json',
      });
}

// Static file handler
Response _staticFileHandler(Request request) {
  final fileName = request.params['file'];
  final file = File('images/$fileName'); // Updated to look in the `images` directory
  print('Looking for file: ${file.path}'); // Log file path for debugging
  if (file.existsSync()) {
    return Response.ok(file.openRead(),
        headers: {'Content-Type': 'image/png'}); // Serve as PNG
  } else {
    print('File not found: ${file.path}');
    return Response.notFound('File not found');
  }
}

// Enhanced Logging Middleware
Middleware enhancedLogging() {
  return (Handler innerHandler) {
    return (Request request) async {
      final start = DateTime.now();
      final response = await innerHandler(request);
      final duration = DateTime.now().difference(start);

      // Log request and response details
      print(''' 
===============================================================
Request: ${request.method} ${request.requestedUri.path}
Status: ${response.statusCode} ${_statusMessage(response.statusCode)}
Duration: ${duration.inMilliseconds} ms
${_logDetails(request, response)}
===============================================================
''');
      return response;
    };
  };
}

String _statusMessage(int statusCode) {
  if (statusCode >= 200 && statusCode < 300) return 'Success';
  if (statusCode >= 300 && statusCode < 400) return 'Redirect';
  if (statusCode >= 400 && statusCode < 500) return 'Client Error';
  if (statusCode >= 500) return 'Server Error';
  return 'Unknown Status';
}

String _logDetails(Request request, Response response) {
  switch (request.requestedUri.path) {
    case '/products':
      return response.statusCode == 200
          ? 'Products have been fetched successfully.'
          : 'Failed to fetch products.';
    case '/cart':
      if (request.method == 'POST') {
        return 'A product was added to the cart.';
      } else if (request.method == 'PUT') {
        return 'A product quantity was updated in the cart.';
      }
      return 'Invalid cart operation.';
    case '/buy':
      return response.statusCode == 200
          ? 'Purchase completed successfully, cart cleared.'
          : 'Purchase operation failed.';
    default:
      return 'Handled request for ${request.requestedUri.path}.';
  }
}

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;
  final handler = Pipeline()
      .addMiddleware(enhancedLogging()) // Use enhanced logging middleware
      .addHandler(_router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
