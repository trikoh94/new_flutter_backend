import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/portfolio_model.dart';
import '../services/firebase_service.dart';
import '../services/huggingface_service.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final HuggingFaceService _huggingfaceService = HuggingFaceService();
  List<PortfolioModel> _portfolios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPortfolios();
  }

  Future<void> _loadPortfolios() async {
    try {
      final portfolios = await _firebaseService.getPortfolios();
      setState(() {
        _portfolios = portfolios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading portfolios: $e')),
        );
      }
    }
  }

  Future<void> _createPortfolio() async {
    try {
      final title =
          await _huggingfaceService.generateText('Generate a portfolio title');
      final content = await _huggingfaceService
          .generateText('Generate a portfolio description');

      final portfolio = PortfolioModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        images: [],
        links: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.createPortfolio(portfolio);
      await _loadPortfolios();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating portfolio: $e')),
        );
      }
    }
  }

  Future<void> _deletePortfolio(String id) async {
    try {
      await _firebaseService.deletePortfolio(id);
      await _loadPortfolios();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting portfolio: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createPortfolio,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _portfolios.isEmpty
              ? const Center(child: Text('No portfolios found'))
              : ListView.builder(
                  itemCount: _portfolios.length,
                  itemBuilder: (context, index) {
                    final portfolio = _portfolios[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(portfolio.title),
                        subtitle: Text(portfolio.content),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deletePortfolio(portfolio.id),
                        ),
                        onTap: () => context.push('/portfolio/${portfolio.id}'),
                      ),
                    );
                  },
                ),
    );
  }
}
